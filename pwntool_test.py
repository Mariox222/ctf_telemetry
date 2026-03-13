from pwn import *
r = remote("example.com", 80)
r.sendline(b"Hello")
print(r.recvline())