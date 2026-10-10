// C_PUSH constant 10
@10
D=A
@SP
A=M
M=D
@SP
M=M+1
// C_PUSH constant 10
@10
D=A
@SP
A=M
M=D
@SP
M=M+1
// eq
@SP
M=M-1
A=M
D=M
@SP
A=M-1
D=M-D
@LABEL_0_TRUE
D;JEQ
@SP
A=M-1
M=0
@LABEL_0_END
0;JMP
(LABEL_0_TRUE)
@SP
A=M-1
M=-1
(LABEL_0_END)
// C_PUSH constant 8
@8
D=A
@SP
A=M
M=D
@SP
M=M+1
// C_PUSH constant 5
@5
D=A
@SP
A=M
M=D
@SP
M=M+1
// gt
@SP
M=M-1
A=M
D=M
@SP
A=M-1
D=M-D
@LABEL_1_TRUE
D;JGT
@SP
A=M-1
M=0
@LABEL_1_END
0;JMP
(LABEL_1_TRUE)
@SP
A=M-1
M=-1
(LABEL_1_END)
// and
@SP
M=M-1
A=M
D=M
@SP
A=M-1
M=M&D
// not
@SP
A=M-1
M=!M
