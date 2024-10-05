format ELF64 executable 

SYS_write equ 1            
SYS_exit equ 60           
SYS_socket equ 41
SYS_bind equ 49
SYS_listen equ 50
SYS_close equ 3
SYS_accept equ 43

AF_INET equ 2
SOCK_STREAM equ 1
INADDR_ANY equ 0

STDOUT equ 1
STDERR equ 2

MAX_CONN equ 5

EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1

macro syscall3 number, a, b, c 
{
  mov rax, number
  mov rdi, a
  mov rsi, b 
  mov rdx, c
  syscall
}

macro syscall2 number, a, b 
{
  mov rax, number
  mov rdi, a 
  mov rsi, b
  syscall
}

macro syscall1 number, a 
{
  mov rax, number
  mov rdi, a
  syscall
}

macro write fd, buf, count
{
  syscall3 SYS_write, fd, buf, count
}

macro bind sockfd, addr, addrlen
{
  syscall3 SYS_bind, sockfd, addr, addrlen
}

macro listen sockfd, backlog 
{
  syscall2 SYS_listen, sockfd, backlog
}

macro accept sockfd, addr, addrlen
{
  syscall3 SYS_accept, sockfd, addr, addrlen
}

macro close fd 
{
  syscall1 SYS_close, fd
}

macro exit code       
{
  mov rax, SYS_exit      
  mov rdi, code          
  syscall                
}

; int socket(int domain, int type, int protocol)
macro socket domain, type, protocol
{
  syscall3 SYS_socket, domain, type, protocol
}

segment readable executable  
entry main                   
main:                        
  write STDOUT, start, start_len 

  write STDOUT, sock_msg, sock_msg_len
  socket AF_INET, SOCK_STREAM, 0
  cmp rax, 0
  jl error
  mov qword [sockfd], rax

  write STDOUT, bind_msg, bind_msg_len
  mov word [servaddr.sin_family], AF_INET
  mov word [servaddr.sin_port], 14619  ; on port 6969
  mov dword [servaddr.sin_addr], INADDR_ANY
  bind [sockfd], servaddr.sin_family, sizeof_servaddr
  cmp rax, 0
  jl error

  write STDOUT, listen_msg, listen_msg_len
  listen [sockfd], MAX_CONN
  cmp rax, 0
  jl error

next_request:
  write STDOUT, accept_msg, accept_msg_len
  accept [sockfd], cliaddr.sin_family, cliaddr_len
  cmp rax, 0
  jl error

  mov qword [connfd], rax
  write [connfd], response, response_len
  
  jmp next_request

  write STDOUT, ok_msg, ok_msg_len
  close [connfd]
  close [sockfd]
  exit EXIT_SUCCESS                     

error:
  write STDERR, error_msg, error_msg_len
  close [connfd]
  close [sockfd]
  exit EXIT_FAILURE

segment readable writeable  

struc servaddr_in
{
  .sin_family dw 0
  .sin_port   dw 0
  .sin_addr   dd 0
  .sin_zero   dq 0
}

sockfd dq -1
connfd dq -1
servaddr servaddr_in
sizeof_servaddr = $ - servaddr.sin_family
cliaddr  servaddr_in
cliaddr_len dd sizeof_servaddr

response db "HTTP/1.1 200 OK", 13, 10
         db "Content-Type: text/html; charset=utf-8", 13, 10           
         db "Connection: close", 13, 10
         db 13, 10
         db "<h1 style='font-size: 4em;'>Lavnish Pandey</h1>", 13, 10
         db "<p style='font-size: 1.5em;'>This simple webpage is served on localhost using Assembly.</p>", 13, 10 
         db "<hr>", 13, 10
         db "<h2 style='font-size: 2.5em;'>Why Assembly?</h2>", 13, 10
         db "<p style='font-size: 1.5em;'>Wanted to know more about syscalls so ...</p>", 13, 10
         db "<hr>", 13, 10
         db "<h2 style='font-size: 2.5em;'>A Small Thought</h2>", 13, 10
         db "<p style='font-size: 1.5em;'>Funny how we use huge frameworks for 'Hello World', when Assembly can handle it all—simple, direct, and efficient.</p>", 13, 10
response_len = $ - response

start db "INFO: Started Web Server!", 10
start_len = $ - start           
sock_msg db "INFO: Starting a socket...", 10
sock_msg_len = $ - sock_msg
ok_msg db "INFO: OK!", 10
ok_msg_len = $ - ok_msg
bind_msg db "INFO: Binding the socket...", 10
bind_msg_len = $ - bind_msg
listen_msg db "INFO: Listening to the socket...", 10
listen_msg_len = $ - listen_msg
accept_msg db "INFO: Waiting for client connections...", 10
accept_msg_len = $ - accept_msg
error_msg db "ERROR!", 10
error_msg_len = $ - error_msg
