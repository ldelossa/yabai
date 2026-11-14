#!/usr/bin/env python3
"""Offline Dock signature inspection. Never opens a process or executes Dock code."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import uuid

ROOT = Path(__file__).resolve().parents[2]
ARCHES = {"arm64e": 0x80000002, "arm64e.x1": 0x8000000C}
LEGACY_STARTS = {
    "dock_spaces": 0x30000, "dppm": 0x50000, "fix_animation": 0x200000,
    "add_space": 0x200000, "remove_space": 0x180000,
    "move_space": 0x180000, "set_front_window": 0x10000,
}
CORE = ("dock_spaces", "add_space", "remove_space")


def checked_slice(data, offset, size):
    if offset < 0 or size < 0 or offset > len(data) or size > len(data) - offset:
        raise ValueError("Mach-O range exceeds file bounds")
    return data[offset:offset + size]


def select_slice(data, arch):
    magic = struct.unpack_from(">I", data)[0]
    if magic == 0xCAFEBABE:
        count = struct.unpack_from(">I", data, 4)[0]
        for i in range(count):
            entry = checked_slice(data, 8 + 20 * i, 20)
            cpu, subtype, offset, size, _ = struct.unpack(">IIIII", entry)
            if cpu == 0x100000C and subtype == ARCHES[arch]:
                return checked_slice(data, offset, size)
        raise ValueError("Requested architecture is absent")
    if magic == 0xCFFAEDFE:
        return data
    raise ValueError("Unsupported Mach-O format")


class MachO:
    def __init__(self, data):
        self.data = data
        magic, self.cpu, self.subtype, _, ncmds, sizecmds, _, _ = struct.unpack(
            "<IIIIIIII", checked_slice(data, 0, 32))
        if magic != 0xFEEDFACF:
            raise ValueError("Not a little-endian 64-bit Mach-O")
        commands_end = 32 + sizecmds
        checked_slice(data, 32, sizecmds)
        self.segments = []
        self.sections = []
        self.uuid = None
        self.function_starts = set()
        starts = None
        pos = 32
        for _ in range(ncmds):
            cmd, size = struct.unpack("<II", checked_slice(data, pos, 8))
            if size < 8 or pos + size > commands_end:
                raise ValueError("Invalid Mach-O load command")
            command = checked_slice(data, pos, size)
            if cmd == 0x19:
                name = command[8:24].split(b"\0")[0].decode()
                vm, vmsize, off, length, _, prot, nsects, _ = struct.unpack_from(
                    "<QQQQiiII", command, 24)
                checked_slice(data, off, length)
                self.segments.append(dict(name=name, vmaddr=vm, vmsize=vmsize,
                                          fileoff=off, filesize=length, protection=prot))
                for i in range(nsects):
                    section = checked_slice(command, 72 + 80 * i, 80)
                    sn = section[:16].split(b"\0")[0].decode()
                    addr, length, off = struct.unpack_from("<QQI", section, 32)
                    flags = struct.unpack_from("<I", section, 64)[0]
                    self.sections.append(dict(name=sn, segment=name, addr=addr,
                                              size=length, offset=off, flags=flags))
            elif cmd == 0x1B:
                self.uuid = str(uuid.UUID(bytes=checked_slice(command, 8, 16)))
            elif cmd == 0x26:
                starts = struct.unpack_from("<II", command, 8)
            pos += size
        self.base = next(s["vmaddr"] for s in self.segments if s["name"] == "__TEXT")
        if starts:
            encoded = checked_slice(data, *starts)
            value = shift = 0
            address = self.base
            for byte in encoded:
                value |= (byte & 0x7F) << shift
                if byte & 0x80:
                    shift += 7
                    if shift > 63:
                        raise ValueError("Invalid function-start ULEB128")
                else:
                    if value == 0:
                        break
                    address += value
                    self.function_starts.add(address)
                    value = shift = 0

    def segment_at(self, address):
        return next((s for s in self.segments
                     if s["vmaddr"] <= address < s["vmaddr"] + s["vmsize"]), None)

    def bytes_at(self, address, size):
        segment = self.segment_at(address)
        if not segment:
            raise ValueError("Unmapped address")
        offset = address - segment["vmaddr"]
        if size > segment["filesize"] - offset:
            raise ValueError("Address has no corresponding file bytes")
        return checked_slice(self.data, segment["fileoff"] + offset, size)


def find_matches(data, pattern, address=0):
    """Keep the runtime scanner's full-byte '?' wildcard semantics."""
    tokens = pattern.split()
    if not tokens or any(len(token) != 2 for token in tokens):
        raise ValueError("Empty or malformed signature")
    expression = b"".join(b"." if token.startswith("?") else
                          re.escape(bytes([int(token, 16)])) for token in tokens)
    # Lookahead reports overlapping matches too, so ambiguity is not hidden.
    return [address + match.start() for match in re.finditer(
        b"(?=" + expression + b")", data, re.DOTALL)
        if (address + match.start()) % 4 == 0]


def decode_adrp_add(data, pc):
    adrp, add = struct.unpack("<II", data)
    if adrp & 0x9F000000 != 0x90000000 or add & 0xFFC00000 != 0x91000000:
        raise ValueError("Expected ADRP followed by unshifted 64-bit ADD immediate")
    register = adrp & 31
    if add & 31 != register or (add >> 5) & 31 != register:
        raise ValueError("ADRP/ADD register mismatch")
    immediate = ((adrp >> 5) & 0x7FFFF) << 2 | ((adrp >> 29) & 3)
    if immediate & (1 << 20):
        immediate -= 1 << 21
    return (pc & ~0xFFF) + (immediate << 12) + ((add >> 10) & 0xFFF)


def source_patterns():
    source = (ROOT / "src/osax/arm64_payload.m").read_text()
    patterns = {}
    for name in LEGACY_STARTS:
        body = source.split("const char *get_" + name + "_pattern(", 1)[1]
        patterns[name] = re.search(r'return "([^"]+)";', body)[1]
    return patterns


def inspect(binary, arch):
    raw = Path(binary).read_bytes()
    image = MachO(select_slice(raw, arch))
    if image.subtype != ARCHES[arch]:
        raise ValueError("Slice subtype differs from requested architecture")
    report = dict(binary=str(binary), sha256=hashlib.sha256(raw).hexdigest(),
                  arch=arch, subtype=hex(image.subtype), uuid=image.uuid, patterns={})
    for name, pattern in source_patterns().items():
        hits = []
        # Inspect instruction sections only; never match constants or another slice.
        for section in image.sections:
            if section["segment"] != "__TEXT" or section["name"] != "__text" or not section["flags"] & 0x80000400:
                continue
            segment = image.segment_at(section["addr"])
            if not segment or not segment["protection"] & 4:
                continue
            data = image.bytes_at(section["addr"], section["size"])
            for address in find_matches(data, pattern, section["addr"]):
                relative = address - image.base
                hit = dict(relative_vmaddr=hex(relative), function_start=address in image.function_starts,
                           in_legacy_window=LEGACY_STARTS[name] <= relative < LEGACY_STARTS[name] + 0x1286A0)
                if name == "dock_spaces":
                    target = decode_adrp_add(image.bytes_at(address, 8), address)
                    target_segment = image.segment_at(target)
                    hit["pointer_slot"] = hex(target - image.base)
                    hit["pointer_segment"] = target_segment["name"] if target_segment else None
                    hit["pointer_writable"] = bool(target_segment and target_segment["protection"] & 2)
                hits.append(hit)
        report["patterns"][name] = dict(count=len(hits), hits=hits)
    return report


def check_core(report):
    """Require a runtime profile, not just a plausible set of byte matches."""
    header = ROOT / "src/osax/dock_27_3.h"
    if not header.exists():
        return False
    source = header.read_text()
    expected = re.search(r'#define DOCK_27_3_UUID "([^"]+)"', source)
    if not expected or report["uuid"].lower() != expected[1].lower() or report["arch"] != "arm64e":
        return False
    for name in CORE:
        match = re.search(r"#define DOCK_27_3_" + name.upper() + r"_OFFSET (0x[0-9a-fA-F]+)", source)
        entry = report["patterns"][name]
        if not match or entry["count"] != 1 or int(entry["hits"][0]["relative_vmaddr"], 16) != int(match[1], 16):
            return False
        hit = entry["hits"][0]
        if name == "dock_spaces":
            pointer = re.search(r"#define DOCK_27_3_POINTER_SLOT_OFFSET (0x[0-9a-fA-F]+)", source)
            if not hit.get("pointer_writable") or not pointer or int(hit["pointer_slot"], 16) != int(pointer[1], 16):
                return False
        elif not hit["function_start"]:
            return False
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", required=True)
    parser.add_argument("--arch", choices=ARCHES, default="arm64e")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--check-core", action="store_true")
    args = parser.parse_args()
    try:
        report = inspect(args.binary, args.arch)
        output = json.dumps(report, indent=2) + "\n"
        if args.report:
            args.report.write_text(output)
        print(output, end="")
        if args.check_core:
            passed = check_core(report)
            print("core signatures: " + ("PASS" if passed else "FAIL"))
            return 0 if passed else 1
        return 0
    except (OSError, ValueError, struct.error, StopIteration) as error:
        parser.exit(1, str(error) + "\n")


if __name__ == "__main__":
    raise SystemExit(main())
