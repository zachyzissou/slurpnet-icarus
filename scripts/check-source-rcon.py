#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import socket
import struct
import sys
from dataclasses import dataclass


SERVERDATA_RESPONSE_VALUE = 0
SERVERDATA_EXECCOMMAND = 2
SERVERDATA_AUTH_RESPONSE = 2
SERVERDATA_AUTH = 3


@dataclass
class Packet:
    request_id: int
    packet_type: int
    body: str


def recv_exact(sock: socket.socket, size: int) -> bytes:
    chunks: list[bytes] = []
    remaining = size
    while remaining:
        chunk = sock.recv(remaining)
        if not chunk:
            raise ConnectionError("RCON socket closed while reading")
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def read_packet(sock: socket.socket) -> Packet:
    (size,) = struct.unpack("<i", recv_exact(sock, 4))
    if size < 10 or size > 4096:
        raise ValueError(f"invalid RCON packet size: {size}")
    payload = recv_exact(sock, size)
    request_id, packet_type = struct.unpack("<ii", payload[:8])
    if payload[-2:] != b"\x00\x00":
        raise ValueError("invalid RCON packet terminator")
    body = payload[8:-2].decode("utf-8", errors="replace")
    return Packet(request_id=request_id, packet_type=packet_type, body=body)


def write_packet(sock: socket.socket, request_id: int, packet_type: int, body: str) -> None:
    body_bytes = body.encode("utf-8")
    payload = struct.pack("<ii", request_id, packet_type) + body_bytes + b"\x00\x00"
    sock.sendall(struct.pack("<i", len(payload)) + payload)


def collect_response(sock: socket.socket, request_id: int) -> str:
    # Source RCON responses may be split. Send an empty command sentinel
    # so the client can stop without waiting for the read timeout.
    sentinel_id = request_id + 1
    write_packet(sock, sentinel_id, SERVERDATA_EXECCOMMAND, "")
    bodies: list[str] = []
    while True:
        packet = read_packet(sock)
        if packet.request_id == sentinel_id:
            break
        if packet.request_id == request_id:
            bodies.append(packet.body)
    return "".join(bodies).strip()


def run(host: str, port: int, password: str, command: str, timeout: float) -> str:
    with socket.create_connection((host, port), timeout=timeout) as sock:
        sock.settimeout(timeout)
        write_packet(sock, 1, SERVERDATA_AUTH, password)
        auth_packets = [read_packet(sock), read_packet(sock)]
        auth_ok = any(
            packet.request_id == 1 and packet.packet_type == SERVERDATA_AUTH_RESPONSE
            for packet in auth_packets
        )
        auth_failed = any(packet.request_id == -1 for packet in auth_packets)
        if auth_failed or not auth_ok:
            raise PermissionError("RCON authentication failed")
        write_packet(sock, 2, SERVERDATA_EXECCOMMAND, command)
        return collect_response(sock, 2)


def main() -> int:
    parser = argparse.ArgumentParser(description="Check Source RCON command execution.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=27037)
    parser.add_argument("--password-env", default="RCON_PASSWORD")
    parser.add_argument("--command", default="listplayers")
    parser.add_argument("--timeout", type=float, default=5.0)
    args = parser.parse_args()

    password = os.environ.get(args.password_env, "")
    if not password:
        print(f"ERROR: {args.password_env} is required", file=sys.stderr)
        return 1
    try:
        output = run(args.host, args.port, password, args.command, args.timeout)
    except Exception as exc:
        print(f"ERROR: Source RCON check failed: {exc}", file=sys.stderr)
        return 1
    print(f"Source RCON check passed: {args.host}:{args.port} command={args.command}")
    if output:
        print(output)
    else:
        print("(empty response)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
