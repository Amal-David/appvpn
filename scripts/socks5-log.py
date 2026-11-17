#!/usr/bin/env python3
"""No-auth SOCKS5 server that prints each CONNECT target. Test exit for the Mac proxy; not for real use."""
import asyncio, ipaddress, sys


async def pipe(reader, writer):
    try:
        while data := await reader.read(65536):
            writer.write(data)
            await writer.drain()
    except OSError:
        pass
    finally:
        writer.close()


async def handle(reader, writer):
    try:
        _, count = await reader.readexactly(2)
        await reader.readexactly(count)
        writer.write(b"\x05\x00")
        _, _, _, kind = await reader.readexactly(4)
        if kind == 1:
            host = str(ipaddress.IPv4Address(await reader.readexactly(4)))
        elif kind == 4:
            host = str(ipaddress.IPv6Address(await reader.readexactly(16)))
        else:
            host = (await reader.readexactly((await reader.readexactly(1))[0])).decode()
        port = int.from_bytes(await reader.readexactly(2), "big")
        print(f"CONNECT {host}:{port}", flush=True)
        up_reader, up_writer = await asyncio.open_connection(host, port)
    except (OSError, asyncio.IncompleteReadError) as error:
        print(f"failed: {error}", flush=True)
        writer.close()
        return
    writer.write(b"\x05\x00\x00\x01" + bytes(6))
    await asyncio.gather(pipe(reader, up_writer), pipe(up_reader, writer))


async def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 1080
    server = await asyncio.start_server(handle, "127.0.0.1", port)
    print(f"listening on 127.0.0.1:{port}", flush=True)
    async with server:
        await server.serve_forever()


asyncio.run(main())
