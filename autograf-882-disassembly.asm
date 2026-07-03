; ============================================================
; Autograf-882 — Disassembly of firmware ROM
; CPU: Intel 8080A (К580ИК80)
;
; Source: 3 × D2764A EPROM, 8KB each, contiguous in address space
; Image size: 24576 bytes ($0000-$5FFF)
;
; Memory Map:
;   $0000-$1FFF = Chip 1 (NearOfHeatsink) — reset, init, low routines
;   $2000-$3FFF = Chip 2 (InMiddle) — main program logic
;   $4000-$5FFF = Chip 3 (FarOfHeatsink) — plotter routines, font tables
;   $E000-$E3FF = I/O ports (8255 PPI ×? 8253 PIT)
; ============================================================

; I/O Ports:
;   $e0  = PPI_A_PORT
;   $e1  = PPI_B_PORT
;   $e2  = PPI_C_PORT
;   $e3  = PPI_CTRL
;   $e4  = PIT_CNTR0
;   $e5  = PIT_CNTR1
;   $e6  = PIT_CNTR2
;   $e7  = PIT_CTRL


RESET:
$0000:  f3                  DI
$0001:  3e 80               MVI      A,$80
$0003:  32 03 e4            STA      $e403
$0006:  21 00 60            LXI      H,$6000
$0009:  01 aa 55            LXI      B,$55aa

F_L_000c:
$000c:  70                  MOV      M,B
$000d:  78                  MOV      A,B
$000e:  be                  CMP      M
$000f:  c2 29 02            JNZ      $0229
$0012:  71                  MOV      M,C
$0013:  79                  MOV      A,C
$0014:  be                  CMP      M
$0015:  c2 29 02            JNZ      $0229
$0018:  23                  INX      H
$0019:  7c                  MOV      A,H
$001a:  fe 68               CPI      $68
$001c:  c2 0c 00            JNZ      $000c
$001f:  31 40 61            LXI      SP,$6140
$0022:  21 03 e0            LXI      H,$e003
$0025:  36 92               MVI      M,$92
$0027:  2b                  DCX      H
$0028:  2b                  DCX      H
$0029:  36 fc               MVI      M,$fc
$002b:  2b                  DCX      H
$002c:  3e 00               MVI      A,$00
$002e:  7e                  MOV      A,M
$002f:  cd af 02            CALL     $02af
$0032:  21 03 e8            LXI      H,$e803
$0035:  c3 3c 00            JMP      $003c
$0038:  f3           DB  $f3
$0039:  c3           DB  $c3
$003a:  e9           DB  $e9
$003b:  19           DB  $19

F_L_003c:
$003c:  36 36               MVI      M,$36
$003e:  36 76               MVI      M,$76
$0040:  3a 02 e0            LDA      $e002
$0043:  4f                  MOV      C,A
$0044:  e6 f0               ANI      $f0
$0046:  fe 60               CPI      $60
$0048:  c2 51 00            JNZ      $0051
$004b:  06 fa               MVI      B,$fa
$004d:  78                  MOV      A,B
$004e:  c3 66 00            JMP      $0066

F_L_0051:
$0051:  3e 80               MVI      A,$80
$0053:  a1                  ANA      C
$0054:  06 0a               MVI      B,$0a
$0056:  ca 5b 00            JZ       $005b
$0059:  06 0e               MVI      B,$0e

F_L_005b:
$005b:  3e 40               MVI      A,$40
$005d:  a1                  ANA      C
$005e:  3e 40               MVI      A,$40
$0060:  ca 65 00            JZ       $0065
$0063:  3e c0               MVI      A,$c0

F_L_0065:
$0065:  b0                  ORA      B

F_L_0066:
$0066:  f5                  PUSH     PSW
$0067:  3e 30               MVI      A,$30
$0069:  a1                  ANA      C
$006a:  11 68 00            LXI      D,$0068
$006d:  a7                  ANA      A
$006e:  ca 84 00            JZ       $0084
$0071:  11 34 00            LXI      D,$0034
$0074:  fe 20               CPI      $20

F_L_0076:
$0076:  ca 84 00            JZ       $0084
$0079:  11 1a 00            LXI      D,$001a
$007c:  fe 10               CPI      $10
$007e:  ca 84 00            JZ       $0084
$0081:  11 0d 00            LXI      D,$000d

F_L_0084:
$0084:  21 00 e8            LXI      H,$e800
$0087:  73                  MOV      M,E
$0088:  72                  MOV      M,D
$0089:  21 01 ec            LXI      H,$ec01
$008c:  f1                  POP      PSW
$008d:  77                  MOV      M,A
$008e:  36 37               MVI      M,$37
$0090:  2b                  DCX      H
$0091:  36 13               MVI      M,$13
$0093:  3a 00 e0            LDA      $e000
$0096:  e6 40               ANI      $40
$0098:  3e 02               MVI      A,$02
$009a:  ca 29 02            JZ       $0229
$009d:  21 64 00            LXI      H,$0064
$00a0:  22 49 61            SHLD     $6149
$00a3:  cd af 00            CALL     $00af
$00a6:  11 bc 1b            LXI      D,$1bbc
$00a9:  cd d0 06            CALL     $06d0
$00ac:  c3 4e 0b            JMP      $0b4e

F_L_00af:
$00af:  21 40 61            LXI      H,$6140

F_L_00b2:
$00b2:  36 00               MVI      M,$00
$00b4:  23                  INX      H
$00b5:  7c                  MOV      A,H
$00b6:  fe 68               CPI      $68
$00b8:  c2 b2 00            JNZ      $00b2
$00bb:  3e 03               MVI      A,$03
$00bd:  32 b2 63            STA      $63b2
$00c0:  cd 3c 22            CALL     $223c
$00c3:  3e ee               MVI      A,$ee
$00c5:  32 01 e0            STA      $e001
$00c8:  21 03 e4            LXI      H,$e403
$00cb:  36 06               MVI      M,$06
$00cd:  36 05               MVI      M,$05
$00cf:  36 0a               MVI      M,$0a
$00d1:  e5                  PUSH     H
$00d2:  21 10 a4            LXI      H,$a410
$00d5:  11 ff ff            LXI      D,$ffff

F_L_00d8:
$00d8:  3a 02 e0            LDA      $e002
$00db:  e6 01               ANI      $01
$00dd:  ca f1 00            JZ       $00f1
$00e0:  19                  DAD      D
$00e1:  da d8 00            JC       $00d8
$00e4:  e1                  POP      H
$00e5:  36 04               MVI      M,$04
$00e7:  3e 03               MVI      A,$03
$00e9:  c3 29 02            JMP      $0229
$00ec:  3e           DB  $3e
$00ed:  32           DB  $32
$00ee:  32           DB  $32
$00ef:  f0           DB  $f0
$00f0:  63           DB  $63

F_L_00f1:
$00f1:  e1                  POP      H
$00f2:  36 04               MVI      M,$04
$00f4:  21 a0 41            LXI      H,$41a0
$00f7:  22 87 63            SHLD     $6387
$00fa:  22 a8 63            SHLD     $63a8
$00fd:  22 ac 63            SHLD     $63ac
$0100:  22 a4 63            SHLD     $63a4
$0103:  21 68 2e            LXI      H,$2e68
$0106:  22 89 63            SHLD     $6389
$0109:  22 aa 63            SHLD     $63aa
$010c:  22 ae 63            SHLD     $63ae
$010f:  22 a6 63            SHLD     $63a6
$0112:  21 28 00            LXI      H,$0028
$0115:  22 9b 63            SHLD     $639b
$0118:  22 9d 63            SHLD     $639d
$011b:  3e c1               MVI      A,$c1
$011d:  32 57 62            STA      $6257
$0120:  cd 0c 11            CALL     $110c
$0123:  3a f0 63            LDA      $63f0
$0126:  f6 02               ORI      $02
$0128:  32 f0 63            STA      $63f0

F_L_012b:
$012b:  21 00 00            LXI      H,$0000
$012e:  22 bd 63            SHLD     $63bd
$0131:  22 bf 63            SHLD     $63bf
$0134:  21 28 00            LXI      H,$0028
$0137:  22 9d 63            SHLD     $639d
$013a:  23                  INX      H
$013b:  22 9d 63            SHLD     $639d
$013e:  cd 52 22            CALL     $2252
$0141:  3a 02 e0            LDA      $e002
$0144:  e6 04               ANI      $04
$0146:  c2 2b 01            JNZ      $012b
$0149:  21 78 00            LXI      H,$0078
$014c:  22 bf 63            SHLD     $63bf
$014f:  21 00 00            LXI      H,$0000
$0152:  22 bd 63            SHLD     $63bd
$0155:  cd 52 22            CALL     $2252
$0158:  3e 68               MVI      A,$68
$015a:  32 57 62            STA      $6257

F_L_015d:
$015d:  21 00 00            LXI      H,$0000
$0160:  22 bf 63            SHLD     $63bf
$0163:  22 bd 63            SHLD     $63bd
$0166:  21 29 00            LXI      H,$0029
$0169:  22 9d 63            SHLD     $639d
$016c:  cd 52 22            CALL     $2252
$016f:  af                  XRA      A

F_L_0170:
$0170:  3d                  DCR      A
$0171:  c2 70 01            JNZ      $0170
$0174:  3a 02 e0            LDA      $e002
$0177:  e6 04               ANI      $04
$0179:  c2 5d 01            JNZ      $015d
$017c:  21 28 00            LXI      H,$0028
$017f:  22 bf 63            SHLD     $63bf
$0182:  21 00 00            LXI      H,$0000
$0185:  22 bd 63            SHLD     $63bd
$0188:  cd 52 22            CALL     $2252
$018b:  21 b8 0b            LXI      H,$0bb8
$018e:  22 c1 63            SHLD     $63c1
$0191:  21 e0 0b            LXI      H,$0be0
$0194:  22 9b 63            SHLD     $639b
$0197:  21 00 00            LXI      H,$0000
$019a:  22 c3 63            SHLD     $63c3
$019d:  21 28 00            LXI      H,$0028
$01a0:  22 9d 63            SHLD     $639d
$01a3:  3e 2e               MVI      A,$2e
$01a5:  32 01 e0            STA      $e001
$01a8:  3e 68               MVI      A,$68
$01aa:  32 57 62            STA      $6257
$01ad:  cd 26 06            CALL     $0626
$01b0:  3e ff               MVI      A,$ff
$01b2:  32 40 63            STA      $6340

F_L_01b5:
$01b5:  3a 00 e0            LDA      $e000
$01b8:  e6 40               ANI      $40
$01ba:  ca b5 01            JZ       $01b5
$01bd:  cd 16 22            CALL     $2216
$01c0:  cd 3c 22            CALL     $223c
$01c3:  3e 31               MVI      A,$31
$01c5:  32 5a 62            STA      $625a
$01c8:  3e 01               MVI      A,$01
$01ca:  32 d3 63            STA      $63d3
$01cd:  21 90 06            LXI      H,$0690
$01d0:  22 d1 63            SHLD     $63d1
$01d3:  cd 11 09            CALL     $0911
$01d6:  21 01 00            LXI      H,$0001
$01d9:  22 93 63            SHLD     $6393
$01dc:  22 97 63            SHLD     $6397
$01df:  2a a4 63            LHLD     $63a4
$01e2:  22 64 62            SHLD     $6264
$01e5:  22 6d 63            SHLD     $636d
$01e8:  22 87 63            SHLD     $6387
$01eb:  22 7f 63            SHLD     $637f
$01ee:  2a a6 63            LHLD     $63a6
$01f1:  22 89 63            SHLD     $6389
$01f4:  22 66 62            SHLD     $6266
$01f7:  22 6f 63            SHLD     $636f
$01fa:  22 81 63            SHLD     $6381
$01fd:  21 30 75            LXI      H,$7530
$0200:  22 e1 63            SHLD     $63e1
$0203:  21 fd 63            LXI      H,$63fd
$0206:  22 f6 63            SHLD     $63f6
$0209:  22 f8 63            SHLD     $63f8
$020c:  cd af 02            CALL     $02af
$020f:  cd 77 0e            CALL     $0e77
$0212:  cd 94 40            CALL     $4094
$0215:  01 ce 0a            LXI      B,$0ace
$0218:  cd 3e 0a            CALL     $0a3e
$021b:  3a 02 e0            LDA      $e002
$021e:  e6 80               ANI      $80
$0220:  47                  MOV      B,A
$0221:  3a f0 63            LDA      $63f0
$0224:  b0                  ORA      B
$0225:  32 f0 63            STA      $63f0
$0228:  c9                  RET

F_L_0229:
$0229:  17                  RAL
$022a:  17                  RAL
$022b:  f6 c0               ORI      $c0
$022d:  e6 fc               ANI      $fc
$022f:  47                  MOV      B,A
$0230:  3e a0               MVI      A,$a0
$0232:  32 01 e4            STA      $e401

F_L_0235:
$0235:  3e fc               MVI      A,$fc
$0237:  32 01 e0            STA      $e001
$023a:  21 01 e8            LXI      H,$e801
$023d:  11 4a 0f            LXI      D,$0f4a
$0240:  73                  MOV      M,E
$0241:  72                  MOV      M,D
$0242:  11 ff ff            LXI      D,$ffff
$0245:  21 10 27            LXI      H,$2710

F_L_0248:
$0248:  19                  DAD      D
$0249:  da 48 02            JC       $0248
$024c:  78                  MOV      A,B
$024d:  32 01 e0            STA      $e001
$0250:  21 01 e8            LXI      H,$e801
$0253:  11 0d 04            LXI      D,$040d
$0256:  73                  MOV      M,E
$0257:  72                  MOV      M,D
$0258:  11 ff ff            LXI      D,$ffff
$025b:  21 10 27            LXI      H,$2710

F_L_025e:
$025e:  19                  DAD      D
$025f:  da 5e 02            JC       $025e
$0262:  c3 35 02            JMP      $0235

F_L_0265:
$0265:  f5                  PUSH     PSW
$0266:  3a 57 62            LDA      $6257
$0269:  32 59 62            STA      $6259
$026c:  3e c4               MVI      A,$c4
$026e:  32 57 62            STA      $6257
$0271:  f1                  POP      PSW
$0272:  c9                  RET

F_L_0273:
$0273:  f5                  PUSH     PSW
$0274:  3a 59 62            LDA      $6259
$0277:  32 57 62            STA      $6257
$027a:  f1                  POP      PSW
$027b:  c9                  RET

F_L_027c:
$027c:  3a 8b 63            LDA      $638b
$027f:  32 8c 63            STA      $638c
$0282:  e6 fd               ANI      $fd
$0284:  32 8b 63            STA      $638b
$0287:  c9                  RET

F_L_0288:
$0288:  3a 8c 63            LDA      $638c
$028b:  32 8b 63            STA      $638b
$028e:  c9                  RET

F_L_028f:
$028f:  3a 68 62            LDA      $6268
$0292:  32 69 62            STA      $6269
$0295:  af                  XRA      A
$0296:  32 68 62            STA      $6268
$0299:  c9                  RET

F_L_029a:
$029a:  3a 69 62            LDA      $6269
$029d:  32 68 62            STA      $6268
$02a0:  c9                  RET
$02a1:  3a 2f 63            LDA      $632f
$02a4:  32 5a 62            STA      $625a
$02a7:  c9                  RET
$02a8:  3a 5a 62            LDA      $625a
$02ab:  32 2f 63            STA      $632f
$02ae:  c9                  RET

F_L_02af:
$02af:  3e 03               MVI      A,$03
$02b1:  32 03 e0            STA      $e003
$02b4:  af                  XRA      A
$02b5:  32 03 e0            STA      $e003

F_L_02b8:
$02b8:  3a 00 e0            LDA      $e000
$02bb:  2f                  CMA
$02bc:  e6 3f               ANI      $3f
$02be:  c9                  RET

F_L_02bf:
$02bf:  3e 01               MVI      A,$01
$02c1:  32 03 e0            STA      $e003
$02c4:  3e 02               MVI      A,$02
$02c6:  32 03 e0            STA      $e003
$02c9:  c3 b8 02            JMP      $02b8

F_L_02cc:
$02cc:  0e 13               MVI      C,$13
$02ce:  cd e0 0a            CALL     $0ae0
$02d1:  cd af 02            CALL     $02af
$02d4:  e6 0f               ANI      $0f
$02d6:  4f                  MOV      C,A
$02d7:  06 19               MVI      B,$19

F_L_02d9:
$02d9:  cd af 02            CALL     $02af
$02dc:  b9                  CMP      C
$02dd:  c2 9a 03            JNZ      $039a
$02e0:  05                  DCR      B
$02e1:  c2 d9 02            JNZ      $02d9
$02e4:  79                  MOV      A,C
$02e5:  fe 04               CPI      $04
$02e7:  c2 ef 02            JNZ      $02ef
$02ea:  3e 06               MVI      A,$06
$02ec:  c3 14 03            JMP      $0314

F_L_02ef:
$02ef:  fe 08               CPI      $08
$02f1:  c2 f9 02            JNZ      $02f9
$02f4:  3e 04               MVI      A,$04
$02f6:  c3 14 03            JMP      $0314

F_L_02f9:
$02f9:  fe 01               CPI      $01
$02fb:  c2 08 03            JNZ      $0308
$02fe:  3e 0a               MVI      A,$0a
$0300:  32 03 e0            STA      $e003
$0303:  3e 09               MVI      A,$09
$0305:  c3 14 03            JMP      $0314

F_L_0308:
$0308:  fe 02               CPI      $02
$030a:  c2 9a 03            JNZ      $039a
$030d:  3e 0b               MVI      A,$0b
$030f:  32 03 e0            STA      $e003
$0312:  3e 08               MVI      A,$08

F_L_0314:
$0314:  32 03 e0            STA      $e003
$0317:  c5                  PUSH     B
$0318:  01 d3 0a            LXI      B,$0ad3
$031b:  cd 3e 0a            CALL     $0a3e
$031e:  c1                  POP      B

F_L_031f:
$031f:  06 19               MVI      B,$19

F_L_0321:
$0321:  cd af 02            CALL     $02af
$0324:  c2 1f 03            JNZ      $031f
$0327:  05                  DCR      B
$0328:  c2 21 03            JNZ      $0321
$032b:  79                  MOV      A,C
$032c:  fe 08               CPI      $08
$032e:  ca 98 04            JZ       $0498
$0331:  fe 04               CPI      $04
$0333:  ca 43 03            JZ       $0343
$0336:  fe 02               CPI      $02
$0338:  ca 69 06            JZ       $0669
$033b:  fe 01               CPI      $01
$033d:  ca b8 05            JZ       $05b8
$0340:  c3 9a 03            JMP      $039a

F_L_0343:
$0343:  3e 0a               MVI      A,$0a
$0345:  32 03 e4            STA      $e403
$0348:  11 7c 07            LXI      D,$077c
$034b:  cd d0 06            CALL     $06d0
$034e:  3a d3 63            LDA      $63d3
$0351:  32 da 63            STA      $63da
$0354:  2a c1 63            LHLD     $63c1
$0357:  22 c9 63            SHLD     $63c9
$035a:  2a c3 63            LHLD     $63c3
$035d:  22 cb 63            SHLD     $63cb
$0360:  3a 2f 63            LDA      $632f
$0363:  32 cd 63            STA      $63cd
$0366:  3a f0 63            LDA      $63f0
$0369:  47                  MOV      B,A
$036a:  e6 40               ANI      $40
$036c:  ca 8b 03            JZ       $038b
$036f:  3e bf               MVI      A,$bf
$0371:  a0                  ANA      B
$0372:  32 f0 63            STA      $63f0
$0375:  cd 11 09            CALL     $0911
$0378:  21 80 61            LXI      H,$6180
$037b:  11 90 61            LXI      D,$6190
$037e:  cd 11 2c            CALL     $2c11
$0381:  cd 11 2c            CALL     $2c11
$0384:  af                  XRA      A
$0385:  cd 20 2c            CALL     $2c20
$0388:  cd 20 2c            CALL     $2c20

F_L_038b:
$038b:  cd af 02            CALL     $02af
$038e:  c2 9b 04            JNZ      $049b
$0391:  cd bf 02            CALL     $02bf
$0394:  c2 c0 03            JNZ      $03c0
$0397:  c3 8b 03            JMP      $038b

F_L_039a:
$039a:  21 30 75            LXI      H,$7530
$039d:  22 e1 63            SHLD     $63e1
$03a0:  11 bc 1b            LXI      D,$1bbc
$03a3:  cd d0 06            CALL     $06d0
$03a6:  3e 0f               MVI      A,$0f
$03a8:  32 e0 63            STA      $63e0
$03ab:  21 03 e0            LXI      H,$e003
$03ae:  36 07               MVI      M,$07
$03b0:  36 05               MVI      M,$05
$03b2:  01 db 0a            LXI      B,$0adb
$03b5:  cd 3e 0a            CALL     $0a3e
$03b8:  0e 11               MVI      C,$11
$03ba:  cd e0 0a            CALL     $0ae0
$03bd:  c3 e1 1b            JMP      $1be1

F_L_03c0:
$03c0:  4f                  MOV      C,A
$03c1:  3a f1 63            LDA      $63f1
$03c4:  e6 02               ANI      $02
$03c6:  c2 48 04            JNZ      $0448
$03c9:  3a f0 63            LDA      $63f0
$03cc:  e6 01               ANI      $01
$03ce:  79                  MOV      A,C
$03cf:  c2 1d 04            JNZ      $041d
$03d2:  fe 01               CPI      $01
$03d4:  cc 13 0a            CZ       $0a13
$03d7:  fe 02               CPI      $02
$03d9:  cc fb 09            CZ       $09fb
$03dc:  fe 08               CPI      $08
$03de:  cc ef 09            CZ       $09ef
$03e1:  fe 04               CPI      $04
$03e3:  cc 07 0a            CZ       $0a07
$03e6:  fe 0c               CPI      $0c
$03e8:  cc bb 09            CZ       $09bb
$03eb:  fe 03               CPI      $03
$03ed:  cc e2 09            CZ       $09e2
$03f0:  fe 06               CPI      $06
$03f2:  cc d5 09            CZ       $09d5
$03f5:  fe 09               CPI      $09
$03f7:  cc c8 09            CZ       $09c8

F_L_03fa:
$03fa:  fe 10               CPI      $10
$03fc:  ca 16 04            JZ       $0416
$03ff:  fe 20               CPI      $20
$0401:  c2 8b 03            JNZ      $038b
$0404:  3a 2f 63            LDA      $632f
$0407:  a7                  ANA      A
$0408:  c2 8b 03            JNZ      $038b
$040b:  cd 16 22            CALL     $2216
$040e:  3e ff               MVI      A,$ff

F_L_0410:
$0410:  32 2f 63            STA      $632f
$0413:  c3 8b 03            JMP      $038b

F_L_0416:
$0416:  cd 3c 22            CALL     $223c
$0419:  af                  XRA      A
$041a:  c3 10 04            JMP      $0410

F_L_041d:
$041d:  fe 02               CPI      $02
$041f:  cc 13 0a            CZ       $0a13
$0422:  fe 04               CPI      $04
$0424:  cc fb 09            CZ       $09fb
$0427:  fe 01               CPI      $01
$0429:  cc ef 09            CZ       $09ef
$042c:  fe 08               CPI      $08
$042e:  cc 07 0a            CZ       $0a07
$0431:  fe 09               CPI      $09
$0433:  cc bb 09            CZ       $09bb
$0436:  fe 06               CPI      $06
$0438:  cc e2 09            CZ       $09e2
$043b:  fe 0c               CPI      $0c
$043d:  cc d5 09            CZ       $09d5
$0440:  fe 03               CPI      $03
$0442:  cc c8 09            CZ       $09c8
$0445:  c3 fa 03            JMP      $03fa

F_L_0448:
$0448:  79                  MOV      A,C
$0449:  fe 20               CPI      $20
$044b:  ca 6b 04            JZ       $046b
$044e:  fe 10               CPI      $10
$0450:  ca 84 04            JZ       $0484
$0453:  fe 05               CPI      $05
$0455:  cc e0 06            CZ       $06e0
$0458:  fe 0a               CPI      $0a
$045a:  cc da 06            CZ       $06da
$045d:  fe 0b               CPI      $0b
$045f:  ca 65 04            JZ       $0465
$0462:  c3 8b 03            JMP      $038b

F_L_0465:
$0465:  cd da 06            CALL     $06da
$0468:  c3 65 04            JMP      $0465

F_L_046b:
$046b:  01 d3 0a            LXI      B,$0ad3
$046e:  cd 3e 0a            CALL     $0a3e
$0471:  3a d3 63            LDA      $63d3
$0474:  fe 07               CPI      $07
$0476:  c2 7b 04            JNZ      $047b
$0479:  3e 00               MVI      A,$00

F_L_047b:
$047b:  3c                  INR      A

F_L_047c:
$047c:  c6 30               ADI      $30
$047e:  cd 91 08            CALL     $0891
$0481:  c3 8b 03            JMP      $038b

F_L_0484:
$0484:  01 d3 0a            LXI      B,$0ad3
$0487:  cd 3e 0a            CALL     $0a3e
$048a:  3a d3 63            LDA      $63d3
$048d:  fe 01               CPI      $01
$048f:  c2 94 04            JNZ      $0494
$0492:  3e 08               MVI      A,$08

F_L_0494:
$0494:  3d                  DCR      A
$0495:  c3 7c 04            JMP      $047c

F_L_0498:
$0498:  c3 9a 03            JMP      $039a

F_L_049b:
$049b:  4f                  MOV      C,A
$049c:  fe 20               CPI      $20
$049e:  ca bd 04            JZ       $04bd
$04a1:  fe 10               CPI      $10
$04a3:  ca d2 04            JZ       $04d2
$04a6:  fe 08               CPI      $08
$04a8:  ca ea 04            JZ       $04ea
$04ab:  fe 04               CPI      $04
$04ad:  ca 26 05            JZ       $0526
$04b0:  fe 02               CPI      $02
$04b2:  ca a5 05            JZ       $05a5
$04b5:  fe 01               CPI      $01
$04b7:  ca 92 05            JZ       $0592
$04ba:  c3 8b 03            JMP      $038b

F_L_04bd:
$04bd:  01 d7 0a            LXI      B,$0ad7
$04c0:  cd 3e 0a            CALL     $0a3e
$04c3:  2a c1 63            LHLD     $63c1
$04c6:  22 80 61            SHLD     $6180
$04c9:  2a c3 63            LHLD     $63c3
$04cc:  22 82 61            SHLD     $6182
$04cf:  c3 8b 03            JMP      $038b

F_L_04d2:
$04d2:  01 db 0a            LXI      B,$0adb
$04d5:  cd 3e 0a            CALL     $0a3e
$04d8:  2a c1 63            LHLD     $63c1
$04db:  22 84 61            SHLD     $6184
$04de:  2a c3 63            LHLD     $63c3
$04e1:  22 86 61            SHLD     $6186
$04e4:  cd d1 12            CALL     $12d1
$04e7:  c3 8b 03            JMP      $038b

F_L_04ea:
$04ea:  c5                  PUSH     B
$04eb:  01 d3 0a            LXI      B,$0ad3
$04ee:  cd 3e 0a            CALL     $0a3e
$04f1:  c1                  POP      B

F_L_04f2:
$04f2:  06 19               MVI      B,$19

F_L_04f4:
$04f4:  cd af 02            CALL     $02af
$04f7:  c2 f2 04            JNZ      $04f2
$04fa:  05                  DCR      B
$04fb:  c2 f4 04            JNZ      $04f4
$04fe:  3a f1 63            LDA      $63f1
$0501:  4f                  MOV      C,A
$0502:  e6 02               ANI      $02
$0504:  c2 1b 05            JNZ      $051b
$0507:  3e 02               MVI      A,$02
$0509:  b1                  ORA      C
$050a:  32 f1 63            STA      $63f1
$050d:  3e 04               MVI      A,$04

F_L_050f:
$050f:  32 03 e0            STA      $e003
$0512:  01 d7 0a            LXI      B,$0ad7
$0515:  cd 3e 0a            CALL     $0a3e
$0518:  c3 8b 03            JMP      $038b

F_L_051b:
$051b:  3e fd               MVI      A,$fd
$051d:  a1                  ANA      C
$051e:  32 f1 63            STA      $63f1
$0521:  3e 05               MVI      A,$05
$0523:  c3 0f 05            JMP      $050f

F_L_0526:
$0526:  06 19               MVI      B,$19

F_L_0528:
$0528:  cd af 02            CALL     $02af
$052b:  b9                  CMP      C
$052c:  c2 8b 03            JNZ      $038b
$052f:  05                  DCR      B
$0530:  c2 28 05            JNZ      $0528
$0533:  3e 05               MVI      A,$05
$0535:  32 03 e0            STA      $e003
$0538:  3e 07               MVI      A,$07
$053a:  32 03 e0            STA      $e003

F_L_053d:
$053d:  01 d3 0a            LXI      B,$0ad3
$0540:  cd 3e 0a            CALL     $0a3e
$0543:  06 19               MVI      B,$19

F_L_0545:
$0545:  cd af 02            CALL     $02af
$0548:  c2 3d 05            JNZ      $053d
$054b:  05                  DCR      B
$054c:  c2 45 05            JNZ      $0545
$054f:  01 d7 0a            LXI      B,$0ad7
$0552:  cd 3e 0a            CALL     $0a3e
$0555:  3a da 63            LDA      $63da
$0558:  c6 30               ADI      $30
$055a:  cd 91 08            CALL     $0891
$055d:  2a c9 63            LHLD     $63c9
$0560:  22 bd 63            SHLD     $63bd
$0563:  2a cb 63            LHLD     $63cb
$0566:  22 bf 63            SHLD     $63bf
$0569:  cd 52 22            CALL     $2252
$056c:  3a cd 63            LDA      $63cd
$056f:  32 2f 63            STA      $632f
$0572:  21 90 61            LXI      H,$6190
$0575:  11 80 61            LXI      D,$6180
$0578:  cd 11 2c            CALL     $2c11
$057b:  cd 11 2c            CALL     $2c11
$057e:  3a f0 63            LDA      $63f0
$0581:  e6 02               ANI      $02
$0583:  ca 8c 05            JZ       $058c
$0586:  cd 16 22            CALL     $2216
$0589:  c3 8f 05            JMP      $058f

F_L_058c:
$058c:  cd 3c 22            CALL     $223c

F_L_058f:
$058f:  c3 9a 03            JMP      $039a

F_L_0592:
$0592:  3e 0a               MVI      A,$0a
$0594:  32 03 e4            STA      $e403
$0597:  3a f0 63            LDA      $63f0
$059a:  e6 01               ANI      $01
$059c:  cc cb 05            CZ       $05cb
$059f:  cd 26 06            CALL     $0626
$05a2:  c3 8b 03            JMP      $038b

F_L_05a5:
$05a5:  3e 0a               MVI      A,$0a
$05a7:  32 03 e4            STA      $e403
$05aa:  3a f0 63            LDA      $63f0
$05ad:  e6 01               ANI      $01
$05af:  c4 7c 06            CNZ      $067c
$05b2:  cd 26 06            CALL     $0626
$05b5:  c3 8b 03            JMP      $038b

F_L_05b8:
$05b8:  3e 0a               MVI      A,$0a
$05ba:  32 03 e4            STA      $e403
$05bd:  3a f0 63            LDA      $63f0
$05c0:  e6 01               ANI      $01
$05c2:  cc cb 05            CZ       $05cb
$05c5:  cd 26 06            CALL     $0626
$05c8:  c3 9a 03            JMP      $039a

F_L_05cb:
$05cb:  21 68 2e            LXI      H,$2e68
$05ce:  22 bf 63            SHLD     $63bf
$05d1:  21 00 00            LXI      H,$0000
$05d4:  22 bd 63            SHLD     $63bd
$05d7:  cd 52 22            CALL     $2252
$05da:  21 00 00            LXI      H,$0000
$05dd:  22 c1 63            SHLD     $63c1
$05e0:  22 c3 63            SHLD     $63c3
$05e3:  21 68 2e            LXI      H,$2e68
$05e6:  22 87 63            SHLD     $6387
$05e9:  22 a8 63            SHLD     $63a8
$05ec:  22 ac 63            SHLD     $63ac
$05ef:  22 7f 63            SHLD     $637f
$05f2:  22 6d 63            SHLD     $636d
$05f5:  21 d0 20            LXI      H,$20d0
$05f8:  22 89 63            SHLD     $6389
$05fb:  22 aa 63            SHLD     $63aa
$05fe:  22 ae 63            SHLD     $63ae
$0601:  22 81 63            SHLD     $6381
$0604:  22 6f 63            SHLD     $636f
$0607:  21 00 00            LXI      H,$0000
$060a:  22 c1 63            SHLD     $63c1
$060d:  3e 09               MVI      A,$09
$060f:  32 03 e0            STA      $e003
$0612:  3e 0a               MVI      A,$0a
$0614:  32 03 e0            STA      $e003
$0617:  3a f0 63            LDA      $63f0
$061a:  f6 01               ORI      $01
$061c:  32 f0 63            STA      $63f0
$061f:  3e 04               MVI      A,$04
$0621:  32 34 63            STA      $6334
$0624:  37                  STC
$0625:  c9                  RET

F_L_0626:
$0626:  21 00 00            LXI      H,$0000
$0629:  22 bd 63            SHLD     $63bd
$062c:  22 bf 63            SHLD     $63bf
$062f:  cd 52 22            CALL     $2252
$0632:  21 00 00            LXI      H,$0000
$0635:  22 bf 63            SHLD     $63bf
$0638:  2a a8 63            LHLD     $63a8
$063b:  22 bd 63            SHLD     $63bd
$063e:  cd 52 22            CALL     $2252
$0641:  21 00 00            LXI      H,$0000
$0644:  22 bd 63            SHLD     $63bd
$0647:  22 bf 63            SHLD     $63bf
$064a:  cd 52 22            CALL     $2252
$064d:  21 00 00            LXI      H,$0000
$0650:  22 bd 63            SHLD     $63bd
$0653:  2a aa 63            LHLD     $63aa
$0656:  22 bf 63            SHLD     $63bf
$0659:  cd 52 22            CALL     $2252
$065c:  21 00 00            LXI      H,$0000
$065f:  22 bf 63            SHLD     $63bf
$0662:  22 bd 63            SHLD     $63bd
$0665:  cd 52 22            CALL     $2252
$0668:  c9                  RET

F_L_0669:
$0669:  3e 0a               MVI      A,$0a
$066b:  32 03 e4            STA      $e403
$066e:  3a f0 63            LDA      $63f0
$0671:  e6 01               ANI      $01
$0673:  c4 7c 06            CNZ      $067c
$0676:  cd 26 06            CALL     $0626
$0679:  c3 9a 03            JMP      $039a

F_L_067c:
$067c:  21 68 2e            LXI      H,$2e68
$067f:  22 bd 63            SHLD     $63bd
$0682:  21 00 00            LXI      H,$0000
$0685:  22 bf 63            SHLD     $63bf
$0688:  cd 52 22            CALL     $2252
$068b:  21 00 00            LXI      H,$0000
$068e:  22 c1 63            SHLD     $63c1
$0691:  22 c3 63            SHLD     $63c3
$0694:  21 a0 41            LXI      H,$41a0
$0697:  22 87 63            SHLD     $6387
$069a:  22 a8 63            SHLD     $63a8
$069d:  22 ac 63            SHLD     $63ac
$06a0:  22 7f 63            SHLD     $637f
$06a3:  22 6d 63            SHLD     $636d
$06a6:  21 68 2e            LXI      H,$2e68
$06a9:  22 89 63            SHLD     $6389
$06ac:  22 aa 63            SHLD     $63aa
$06af:  22 ae 63            SHLD     $63ae
$06b2:  22 81 63            SHLD     $6381
$06b5:  22 6f 63            SHLD     $636f
$06b8:  3e 08               MVI      A,$08
$06ba:  32 03 e0            STA      $e003
$06bd:  3e 0b               MVI      A,$0b
$06bf:  32 03 e0            STA      $e003
$06c2:  3a f0 63            LDA      $63f0
$06c5:  e6 fe               ANI      $fe
$06c7:  32 f0 63            STA      $63f0
$06ca:  3e 03               MVI      A,$03
$06cc:  32 34 63            STA      $6334
$06cf:  c9                  RET

F_L_06d0:
$06d0:  21 44 61            LXI      H,$6144
$06d3:  36 c3               MVI      M,$c3
$06d5:  23                  INX      H
$06d6:  73                  MOV      M,E
$06d7:  23                  INX      H
$06d8:  72                  MOV      M,D
$06d9:  c9                  RET

F_L_06da:
$06da:  21 ef 55            LXI      H,$55ef
$06dd:  c3 e3 06            JMP      $06e3

F_L_06e0:
$06e0:  21 73 08            LXI      H,$0873

F_L_06e3:
$06e3:  22 dc 63            SHLD     $63dc

F_L_06e6:
$06e6:  cd 62 07            CALL     $0762
$06e9:  ca fe 06            JZ       $06fe
$06ec:  22 5d 63            SHLD     $635d
$06ef:  cd 62 07            CALL     $0762
$06f2:  ca fe 06            JZ       $06fe
$06f5:  22 5f 63            SHLD     $635f
$06f8:  cd e0 1c            CALL     $1ce0
$06fb:  c3 e6 06            JMP      $06e6

F_L_06fe:
$06fe:  fe f0               CPI      $f0
$0700:  ca 61 08            JZ       $0861
$0703:  fe f1               CPI      $f1
$0705:  cc 0c 11            CZ       $110c
$0708:  fe f2               CPI      $f2
$070a:  cc 16 11            CZ       $1116
$070d:  fe f3               CPI      $f3
$070f:  ca bd 07            JZ       $07bd
$0712:  fe f4               CPI      $f4
$0714:  ca 59 07            JZ       $0759
$0717:  fe f5               CPI      $f5
$0719:  ca 31 08            JZ       $0831
$071c:  fe f6               CPI      $f6
$071e:  ca ab 07            JZ       $07ab
$0721:  fe f7               CPI      $f7
$0723:  ca b4 07            JZ       $07b4
$0726:  fe f8               CPI      $f8
$0728:  ca e6 07            JZ       $07e6
$072b:  fe f9               CPI      $f9
$072d:  ca 87 07            JZ       $0787
$0730:  fe fa               CPI      $fa
$0732:  ca a2 07            JZ       $07a2
$0735:  fe fb               CPI      $fb
$0737:  ca 5b 08            JZ       $085b
$073a:  fe fc               CPI      $fc
$073c:  ca 6d 08            JZ       $086d
$073f:  fe fd               CPI      $fd
$0741:  ca 99 07            JZ       $0799
$0744:  fe fe               CPI      $fe
$0746:  ca 4f 08            JZ       $084f
$0749:  fe ef               CPI      $ef
$074b:  ca fd 07            JZ       $07fd
$074e:  fe ee               CPI      $ee
$0750:  ca 1b 08            JZ       $081b
$0753:  fe ff               CPI      $ff
$0755:  c8                  RZ
$0756:  c3 e6 06            JMP      $06e6

F_L_0759:
$0759:  cd 44 61            CALL     $6144
$075c:  cd 91 08            CALL     $0891
$075f:  c3 e6 06            JMP      $06e6

F_L_0762:
$0762:  cd 44 61            CALL     $6144
$0765:  fe 00               CPI      $00
$0767:  6f                  MOV      L,A
$0768:  cd 44 61            CALL     $6144
$076b:  67                  MOV      H,A
$076c:  ca 70 07            JZ       $0770
$076f:  c9                  RET

F_L_0770:
$0770:  fe e0               CPI      $e0
$0772:  d2 79 07            JNC      $0779
$0775:  3e 1e               MVI      A,$1e
$0777:  a7                  ANA      A
$0778:  c9                  RET

F_L_0779:
$0779:  af                  XRA      A
$077a:  7c                  MOV      A,H
$077b:  c9                  RET
$077c:  e5                  PUSH     H
$077d:  2a dc 63            LHLD     $63dc
$0780:  7e                  MOV      A,M
$0781:  23                  INX      H
$0782:  22 dc 63            SHLD     $63dc
$0785:  e1                  POP      H
$0786:  c9                  RET

F_L_0787:
$0787:  cd 62 07            CALL     $0762
$078a:  22 cc 61            SHLD     $61cc
$078d:  cd 62 07            CALL     $0762
$0790:  22 ca 61            SHLD     $61ca
$0793:  cd 1f 39            CALL     $391f
$0796:  c3 e6 06            JMP      $06e6

F_L_0799:
$0799:  cd 62 07            CALL     $0762
$079c:  22 49 61            SHLD     $6149
$079f:  c3 e6 06            JMP      $06e6

F_L_07a2:
$07a2:  cd 44 61            CALL     $6144
$07a5:  32 57 62            STA      $6257
$07a8:  c3 e6 06            JMP      $06e6

F_L_07ab:
$07ab:  cd 44 61            CALL     $6144
$07ae:  cd c0 3a            CALL     $3ac0
$07b1:  c3 e6 06            JMP      $06e6

F_L_07b4:
$07b4:  cd 44 61            CALL     $6144
$07b7:  32 ed 62            STA      $62ed
$07ba:  c3 e6 06            JMP      $06e6

F_L_07bd:
$07bd:  cd 62 07            CALL     $0762
$07c0:  af                  XRA      A
$07c1:  b4                  ORA      H
$07c2:  ca c7 07            JZ       $07c7
$07c5:  26 80               MVI      H,$80

F_L_07c7:
$07c7:  22 8a 62            SHLD     $628a
$07ca:  21 00 00            LXI      H,$0000
$07cd:  22 88 62            SHLD     $6288
$07d0:  22 8c 62            SHLD     $628c
$07d3:  cd 62 07            CALL     $0762
$07d6:  af                  XRA      A
$07d7:  b4                  ORA      H
$07d8:  ca dd 07            JZ       $07dd
$07db:  26 80               MVI      H,$80

F_L_07dd:
$07dd:  22 8e 62            SHLD     $628e
$07e0:  cd 5f 43            CALL     $435f
$07e3:  c3 e6 06            JMP      $06e6

F_L_07e6:
$07e6:  cd 62 07            CALL     $0762
$07e9:  22 35 63            SHLD     $6335
$07ec:  cd 62 07            CALL     $0762
$07ef:  22 37 63            SHLD     $6337
$07f2:  3a ec 62            LDA      $62ec
$07f5:  f6 01               ORI      $01
$07f7:  32 ec 62            STA      $62ec
$07fa:  c3 e6 06            JMP      $06e6

F_L_07fd:
$07fd:  cd 62 07            CALL     $0762
$0800:  22 c6 61            SHLD     $61c6
$0803:  cd 62 07            CALL     $0762
$0806:  22 c8 61            SHLD     $61c8
$0809:  cd 62 07            CALL     $0762
$080c:  22 be 61            SHLD     $61be
$080f:  21 05 00            LXI      H,$0005
$0812:  22 c2 61            SHLD     $61c2
$0815:  cd 14 36            CALL     $3614
$0818:  c3 e6 06            JMP      $06e6

F_L_081b:
$081b:  cd 62 07            CALL     $0762
$081e:  7d                  MOV      A,L
$081f:  a7                  ANA      A
$0820:  ca 25 08            JZ       $0825
$0823:  f6 40               ORI      $40

F_L_0825:
$0825:  32 68 62            STA      $6268
$0828:  21 0a 00            LXI      H,$000a
$082b:  22 6a 62            SHLD     $626a
$082e:  c3 e6 06            JMP      $06e6

F_L_0831:
$0831:  cd 62 07            CALL     $0762
$0834:  22 88 62            SHLD     $6288
$0837:  cd 62 07            CALL     $0762
$083a:  22 8a 62            SHLD     $628a
$083d:  cd 62 07            CALL     $0762
$0840:  22 8c 62            SHLD     $628c
$0843:  cd 62 07            CALL     $0762
$0846:  22 8e 62            SHLD     $628e
$0849:  cd 23 43            CALL     $4323
$084c:  c3 e6 06            JMP      $06e6

F_L_084f:
$084f:  cd 44 61            CALL     $6144
$0852:  32 90 62            STA      $6290
$0855:  cd bc 44            CALL     $44bc
$0858:  c3 e6 06            JMP      $06e6

F_L_085b:
$085b:  cd e5 44            CALL     $44e5
$085e:  c3 e6 06            JMP      $06e6

F_L_0861:
$0861:  cd 26 0e            CALL     $0e26
$0864:  cd 77 0e            CALL     $0e77
$0867:  cd 0c 11            CALL     $110c
$086a:  c3 e6 06            JMP      $06e6

F_L_086d:
$086d:  cd 77 0e            CALL     $0e77
$0870:  c3 e6 06            JMP      $06e6
$0873:  00           DB  $00
$0874:  f0           DB  $f0
$0875:  00           DB  $00
$0876:  f1           DB  $f1
$0877:  00           DB  $00
$0878:  00           DB  $00
$0879:  00           DB  $00
$087a:  00           DB  $00
$087b:  00           DB  $00
$087c:  f2           DB  $f2
$087d:  a0           DB  $a0
$087e:  41           DB  $41
$087f:  00           DB  $00
$0880:  00           DB  $00
$0881:  a0           DB  $a0
$0882:  41           DB  $41
$0883:  68           DB  $68
$0884:  2e           DB  $2e
$0885:  00           DB  $00
$0886:  00           DB  $00
$0887:  68           DB  $68
$0888:  2e           DB  $2e
$0889:  00           DB  $00
$088a:  00           DB  $00
$088b:  00           DB  $00
$088c:  00           DB  $00
$088d:  00           DB  $00
$088e:  ff           DB  $ff
$088f:  00           DB  $00
$0890:  ff           DB  $ff

F_L_0891:
$0891:  f5                  PUSH     PSW
$0892:  3e 0d               MVI      A,$0d
$0894:  32 03 e0            STA      $e003
$0897:  f1                  POP      PSW
$0898:  d6 30               SUI      $30
$089a:  da 5d 09            JC       $095d
$089d:  fe 08               CPI      $08
$089f:  d2 5d 09            JNC      $095d
$08a2:  a7                  ANA      A
$08a3:  ca 5d 09            JZ       $095d
$08a6:  47                  MOV      B,A
$08a7:  3a d3 63            LDA      $63d3
$08aa:  b8                  CMP      B
$08ab:  ca 5d 09            JZ       $095d
$08ae:  78                  MOV      A,B
$08af:  32 d3 63            STA      $63d3
$08b2:  2a c1 63            LHLD     $63c1
$08b5:  22 d4 63            SHLD     $63d4
$08b8:  2a c3 63            LHLD     $63c3
$08bb:  22 d6 63            SHLD     $63d6
$08be:  21 ad 09            LXI      H,$09ad
$08c1:  d6 01               SUI      $01
$08c3:  87                  ADD      A
$08c4:  4f                  MOV      C,A
$08c5:  af                  XRA      A
$08c6:  47                  MOV      B,A
$08c7:  09                  DAD      B
$08c8:  5e                  MOV      E,M
$08c9:  23                  INX      H
$08ca:  56                  MOV      D,M
$08cb:  eb                  XCHG
$08cc:  22 d1 63            SHLD     $63d1
$08cf:  3a 2f 63            LDA      $632f
$08d2:  32 30 63            STA      $6330
$08d5:  af                  XRA      A
$08d6:  32 2f 63            STA      $632f
$08d9:  2a cf 63            LHLD     $63cf
$08dc:  cd 34 09            CALL     $0934
$08df:  cd 63 09            CALL     $0963

F_L_08e2:
$08e2:  2a d1 63            LHLD     $63d1
$08e5:  22 cf 63            SHLD     $63cf
$08e8:  cd 34 09            CALL     $0934
$08eb:  cd 63 09            CALL     $0963
$08ee:  2a d4 63            LHLD     $63d4
$08f1:  22 bd 63            SHLD     $63bd
$08f4:  2a d6 63            LHLD     $63d6
$08f7:  22 bf 63            SHLD     $63bf
$08fa:  cd 52 22            CALL     $2252

F_L_08fd:
$08fd:  3a 00 e0            LDA      $e000
$0900:  e6 40               ANI      $40
$0902:  ca fd 08            JZ       $08fd
$0905:  3e 0c               MVI      A,$0c
$0907:  32 03 e0            STA      $e003
$090a:  3a 30 63            LDA      $6330
$090d:  32 2f 63            STA      $632f
$0910:  c9                  RET

F_L_0911:
$0911:  2a c1 63            LHLD     $63c1
$0914:  22 d4 63            SHLD     $63d4
$0917:  2a c3 63            LHLD     $63c3
$091a:  22 d6 63            SHLD     $63d6
$091d:  3e 0a               MVI      A,$0a
$091f:  32 03 e4            STA      $e403
$0922:  3e 0d               MVI      A,$0d
$0924:  32 03 e0            STA      $e003
$0927:  3a 2f 63            LDA      $632f
$092a:  32 30 63            STA      $6330
$092d:  af                  XRA      A
$092e:  32 2f 63            STA      $632f
$0931:  c3 e2 08            JMP      $08e2

F_L_0934:
$0934:  3a f0 63            LDA      $63f0
$0937:  e6 01               ANI      $01
$0939:  ca 51 09            JZ       $0951
$093c:  eb                  XCHG
$093d:  21 68 2e            LXI      H,$2e68
$0940:  cd f0 27            CALL     $27f0
$0943:  22 bd 63            SHLD     $63bd
$0946:  2a c3 63            LHLD     $63c3
$0949:  22 bf 63            SHLD     $63bf

F_L_094c:
$094c:  cd 52 22            CALL     $2252
$094f:  af                  XRA      A
$0950:  c9                  RET

F_L_0951:
$0951:  22 bf 63            SHLD     $63bf
$0954:  2a c1 63            LHLD     $63c1
$0957:  22 bd 63            SHLD     $63bd
$095a:  c3 4c 09            JMP      $094c

F_L_095d:
$095d:  3e 34               MVI      A,$34
$095f:  32 de 63            STA      $63de
$0962:  c9                  RET

F_L_0963:
$0963:  21 03 e4            LXI      H,$e403

F_L_0966:
$0966:  3a 00 e0            LDA      $e000
$0969:  e6 40               ANI      $40
$096b:  ca 66 09            JZ       $0966
$096e:  36 07               MVI      M,$07
$0970:  36 04               MVI      M,$04
$0972:  11 ff ff            LXI      D,$ffff
$0975:  21 10 a4            LXI      H,$a410

F_L_0978:
$0978:  3a 02 e0            LDA      $e002
$097b:  e6 02               ANI      $02
$097d:  ca 89 09            JZ       $0989
$0980:  19                  DAD      D
$0981:  da 78 09            JC       $0978
$0984:  3e 07               MVI      A,$07
$0986:  c3 29 02            JMP      $0229

F_L_0989:
$0989:  21 03 e4            LXI      H,$e403
$098c:  36 06               MVI      M,$06
$098e:  36 05               MVI      M,$05
$0990:  21 10 a4            LXI      H,$a410
$0993:  11 ff ff            LXI      D,$ffff

F_L_0996:
$0996:  3a 02 e0            LDA      $e002
$0999:  e6 01               ANI      $01
$099b:  ca a7 09            JZ       $09a7
$099e:  19                  DAD      D
$099f:  da 96 09            JC       $0996
$09a2:  3e 07               MVI      A,$07
$09a4:  c3 29 02            JMP      $0229

F_L_09a7:
$09a7:  3e 04               MVI      A,$04
$09a9:  32 03 e4            STA      $e403
$09ac:  c9                  RET
$09ad:  90                  SUB      B
$09ae:  06 08               MVI      B,$08
$09b0:  0c                  INR      C
$09b1:  80                  ADD      B
$09b2:  11 f8 16            LXI      D,$16f8
$09b5:  70                  MOV      M,B
$09b6:  1c                  INR      E
$09b7:  e8                  RPE
$09b8:  21 60 27            LXI      H,$2760

F_L_09bb:
$09bb:  f5                  PUSH     PSW
$09bc:  2a c3 63            LHLD     $63c3
$09bf:  23                  INX      H
$09c0:  eb                  XCHG
$09c1:  2a c1 63            LHLD     $63c1
$09c4:  23                  INX      H
$09c5:  c3 1c 0a            JMP      $0a1c

F_L_09c8:
$09c8:  f5                  PUSH     PSW
$09c9:  2a c3 63            LHLD     $63c3
$09cc:  2b                  DCX      H
$09cd:  eb                  XCHG
$09ce:  2a c1 63            LHLD     $63c1
$09d1:  23                  INX      H
$09d2:  c3 1c 0a            JMP      $0a1c

F_L_09d5:
$09d5:  f5                  PUSH     PSW
$09d6:  2a c3 63            LHLD     $63c3
$09d9:  23                  INX      H
$09da:  eb                  XCHG
$09db:  2a c1 63            LHLD     $63c1
$09de:  2b                  DCX      H
$09df:  c3 1c 0a            JMP      $0a1c

F_L_09e2:
$09e2:  f5                  PUSH     PSW
$09e3:  2a c3 63            LHLD     $63c3
$09e6:  2b                  DCX      H
$09e7:  eb                  XCHG
$09e8:  2a c1 63            LHLD     $63c1
$09eb:  2b                  DCX      H
$09ec:  c3 1c 0a            JMP      $0a1c

F_L_09ef:
$09ef:  f5                  PUSH     PSW
$09f0:  2a c3 63            LHLD     $63c3
$09f3:  eb                  XCHG
$09f4:  2a c1 63            LHLD     $63c1
$09f7:  23                  INX      H
$09f8:  c3 1c 0a            JMP      $0a1c

F_L_09fb:
$09fb:  f5                  PUSH     PSW
$09fc:  2a c3 63            LHLD     $63c3
$09ff:  eb                  XCHG
$0a00:  2a c1 63            LHLD     $63c1
$0a03:  2b                  DCX      H
$0a04:  c3 1c 0a            JMP      $0a1c

F_L_0a07:
$0a07:  f5                  PUSH     PSW
$0a08:  2a c3 63            LHLD     $63c3
$0a0b:  23                  INX      H
$0a0c:  eb                  XCHG
$0a0d:  2a c1 63            LHLD     $63c1
$0a10:  c3 1c 0a            JMP      $0a1c

F_L_0a13:
$0a13:  f5                  PUSH     PSW
$0a14:  2a c3 63            LHLD     $63c3
$0a17:  2b                  DCX      H
$0a18:  eb                  XCHG
$0a19:  2a c1 63            LHLD     $63c1

F_L_0a1c:
$0a1c:  7c                  MOV      A,H
$0a1d:  17                  RAL
$0a1e:  da 32 0a            JC       $0a32

F_L_0a21:
$0a21:  7a                  MOV      A,D
$0a22:  17                  RAL
$0a23:  da 38 0a            JC       $0a38

F_L_0a26:
$0a26:  22 bd 63            SHLD     $63bd
$0a29:  eb                  XCHG
$0a2a:  22 bf 63            SHLD     $63bf
$0a2d:  cd 52 22            CALL     $2252
$0a30:  f1                  POP      PSW
$0a31:  c9                  RET

F_L_0a32:
$0a32:  21 00 00            LXI      H,$0000
$0a35:  c3 21 0a            JMP      $0a21

F_L_0a38:
$0a38:  11 00 00            LXI      D,$0000
$0a3b:  c3 26 0a            JMP      $0a26

F_L_0a3e:
$0a3e:  0a                  LDAX     B
$0a3f:  a7                  ANA      A
$0a40:  c8                  RZ
$0a41:  fa 6f 0a            JM       $0a6f
$0a44:  fe 1d               CPI      $1d
$0a46:  d0                  RNC
$0a47:  26 00               MVI      H,$00
$0a49:  6f                  MOV      L,A
$0a4a:  29                  DAD      H
$0a4b:  11 90 0a            LXI      D,$0a90
$0a4e:  19                  DAD      D
$0a4f:  5e                  MOV      E,M
$0a50:  23                  INX      H
$0a51:  56                  MOV      D,M
$0a52:  21 01 e8            LXI      H,$e801
$0a55:  73                  MOV      M,E
$0a56:  72                  MOV      M,D
$0a57:  3e 0f               MVI      A,$0f
$0a59:  32 03 e4            STA      $e403
$0a5c:  2a e3 63            LHLD     $63e3
$0a5f:  11 ff ff            LXI      D,$ffff

F_L_0a62:
$0a62:  19                  DAD      D
$0a63:  da 62 0a            JC       $0a62

F_L_0a66:
$0a66:  3e 0e               MVI      A,$0e
$0a68:  32 03 e4            STA      $e403
$0a6b:  03                  INX      B
$0a6c:  c3 3e 0a            JMP      $0a3e

F_L_0a6f:
$0a6f:  fe 85               CPI      $85
$0a71:  d0                  RNC
$0a72:  e6 0f               ANI      $0f
$0a74:  6f                  MOV      L,A
$0a75:  26 00               MVI      H,$00
$0a77:  29                  DAD      H
$0a78:  11 86 0a            LXI      D,$0a86
$0a7b:  19                  DAD      D
$0a7c:  5e                  MOV      E,M
$0a7d:  23                  INX      H
$0a7e:  56                  MOV      D,M
$0a7f:  eb                  XCHG
$0a80:  22 e3 63            SHLD     $63e3
$0a83:  c3 66 0a            JMP      $0a66
$0a86:  80           DB  $80
$0a87:  0c           DB  $0c
$0a88:  00           DB  $00
$0a89:  19           DB  $19
$0a8a:  00           DB  $00
$0a8b:  32           DB  $32
$0a8c:  00           DB  $00
$0a8d:  64           DB  $64
$0a8e:  00           DB  $00
$0a8f:  c8           DB  $c8
$0a90:  28           DB  $28
$0a91:  3d           DB  $3d
$0a92:  7c           DB  $7c
$0a93:  36           DB  $36
$0a94:  8a           DB  $8a
$0a95:  30           DB  $30
$0a96:  d1           DB  $d1
$0a97:  2d           DB  $2d
$0a98:  d1           DB  $d1
$0a99:  28           DB  $28
$0a9a:  5c           DB  $5c
$0a9b:  24           DB  $24
$0a9c:  66           DB  $66
$0a9d:  20           DB  $20
$0a9e:  94           DB  $94
$0a9f:  1e           DB  $1e
$0aa0:  3e           DB  $3e
$0aa1:  1b           DB  $1b
$0aa2:  45           DB  $45
$0aa3:  18           DB  $18
$0aa4:  e8           DB  $e8
$0aa5:  16           DB  $16
$0aa6:  68           DB  $68
$0aa7:  14           DB  $14
$0aa8:  2f           DB  $2f
$0aa9:  12           DB  $12
$0aaa:  33           DB  $33
$0aab:  10           DB  $10
$0aac:  4a           DB  $4a
$0aad:  0f           DB  $0f
$0aae:  9f           DB  $9f
$0aaf:  0d           DB  $0d
$0ab0:  23           DB  $23
$0ab1:  0c           DB  $0c
$0ab2:  73           DB  $73
$0ab3:  0b           DB  $0b
$0ab4:  34           DB  $34
$0ab5:  0a           DB  $0a
$0ab6:  17           DB  $17
$0ab7:  09           DB  $09
$0ab8:  19           DB  $19
$0ab9:  08           DB  $08
$0aba:  a5           DB  $a5
$0abb:  07           DB  $07
$0abc:  cf           DB  $cf
$0abd:  06           DB  $06
$0abe:  11           DB  $11
$0abf:  06           DB  $06
$0ac0:  ba           DB  $ba
$0ac1:  05           DB  $05
$0ac2:  1a           DB  $1a
$0ac3:  05           DB  $05
$0ac4:  8c           DB  $8c
$0ac5:  04           DB  $04
$0ac6:  0d           DB  $0d
$0ac7:  04           DB  $04
$0ac8:  80           DB  $80
$0ac9:  14           DB  $14
$0aca:  0f           DB  $0f
$0acb:  16           DB  $16
$0acc:  1b           DB  $1b
$0acd:  00           DB  $00
$0ace:  80           DB  $80
$0acf:  14           DB  $14
$0ad0:  0f           DB  $0f
$0ad1:  14           DB  $14
$0ad2:  00           DB  $00
$0ad3:  80           DB  $80
$0ad4:  1b           DB  $1b
$0ad5:  14           DB  $14
$0ad6:  00           DB  $00
$0ad7:  80           DB  $80
$0ad8:  14           DB  $14
$0ad9:  1b           DB  $1b
$0ada:  00           DB  $00
$0adb:  80           DB  $80
$0adc:  14           DB  $14
$0add:  1b           DB  $1b
$0ade:  12           DB  $12
$0adf:  00           DB  $00

F_L_0ae0:
$0ae0:  e5                  PUSH     H
$0ae1:  21 8f 84            LXI      H,$848f

F_L_0ae4:
$0ae4:  2d                  DCR      L
$0ae5:  c2 f0 0a            JNZ      $0af0
$0ae8:  2e f0               MVI      L,$f0
$0aea:  25                  DCR      H
$0aeb:  c2 f0 0a            JNZ      $0af0
$0aee:  e1                  POP      H
$0aef:  c9                  RET

F_L_0af0:
$0af0:  3a 01 ec            LDA      $ec01
$0af3:  2f                  CMA
$0af4:  e6 05               ANI      $05
$0af6:  c2 e4 0a            JNZ      $0ae4
$0af9:  79                  MOV      A,C
$0afa:  32 00 ec            STA      $ec00
$0afd:  e1                  POP      H
$0afe:  c9                  RET

F_L_0aff:
$0aff:  3a 01 ec            LDA      $ec01
$0b02:  e6 02               ANI      $02
$0b04:  ca 32 0b            JZ       $0b32
$0b07:  3a 00 ec            LDA      $ec00
$0b0a:  fe 13               CPI      $13
$0b0c:  c2 32 0b            JNZ      $0b32
$0b0f:  e5                  PUSH     H
$0b10:  21 ff 8f            LXI      H,$8fff

F_L_0b13:
$0b13:  2d                  DCR      L
$0b14:  c2 21 0b            JNZ      $0b21
$0b17:  2e ff               MVI      L,$ff
$0b19:  25                  DCR      H
$0b1a:  c2 21 0b            JNZ      $0b21
$0b1d:  e1                  POP      H
$0b1e:  c3 32 0b            JMP      $0b32

F_L_0b21:
$0b21:  3a 01 ec            LDA      $ec01
$0b24:  e6 02               ANI      $02
$0b26:  ca 13 0b            JZ       $0b13
$0b29:  3a 00 ec            LDA      $ec00
$0b2c:  fe 11               CPI      $11
$0b2e:  c2 13 0b            JNZ      $0b13
$0b31:  e1                  POP      H

F_L_0b32:
$0b32:  3a 01 ec            LDA      $ec01
$0b35:  2f                  CMA
$0b36:  e6 05               ANI      $05
$0b38:  c2 32 0b            JNZ      $0b32
$0b3b:  e5                  PUSH     H
$0b3c:  26 14               MVI      H,$14

F_L_0b3e:
$0b3e:  2e 64               MVI      L,$64

F_L_0b40:
$0b40:  2d                  DCR      L
$0b41:  c2 40 0b            JNZ      $0b40
$0b44:  25                  DCR      H
$0b45:  c2 3e 0b            JNZ      $0b3e
$0b48:  e1                  POP      H
$0b49:  79                  MOV      A,C
$0b4a:  32 00 ec            STA      $ec00
$0b4d:  c9                  RET

F_L_0b4e:
$0b4e:  0e 11               MVI      C,$11
$0b50:  cd e0 0a            CALL     $0ae0
$0b53:  fb                  EI

F_L_0b54:
$0b54:  31 40 61            LXI      SP,$6140

F_L_0b57:
$0b57:  cd 44 61            CALL     $6144

F_L_0b5a:
$0b5a:  3a 48 61            LDA      $6148
$0b5d:  fe 20               CPI      $20
$0b5f:  ca 57 0b            JZ       $0b57
$0b62:  fe 2c               CPI      $2c
$0b64:  ca 57 0b            JZ       $0b57
$0b67:  fe 3b               CPI      $3b
$0b69:  ca 57 0b            JZ       $0b57
$0b6c:  fe 0d               CPI      $0d
$0b6e:  ca 54 0b            JZ       $0b54
$0b71:  5f                  MOV      E,A

F_L_0b72:
$0b72:  cd 44 61            CALL     $6144
$0b75:  fe 20               CPI      $20
$0b77:  ca 57 0b            JZ       $0b57
$0b7a:  fe 2c               CPI      $2c
$0b7c:  ca 57 0b            JZ       $0b57
$0b7f:  fe 3b               CPI      $3b
$0b81:  ca 57 0b            JZ       $0b57
$0b84:  57                  MOV      D,A
$0b85:  cd ae 0b            CALL     $0bae
$0b88:  79                  MOV      A,C
$0b89:  a7                  ANA      A
$0b8a:  c2 91 0b            JNZ      $0b91
$0b8d:  5a                  MOV      E,D
$0b8e:  c3 72 0b            JMP      $0b72

F_L_0b91:
$0b91:  21 d1 0b            LXI      H,$0bd1
$0b94:  06 30               MVI      B,$30
$0b96:  0e 01               MVI      C,$01
$0b98:  c3 9d 0b            JMP      $0b9d

F_L_0b9b:
$0b9b:  23                  INX      H
$0b9c:  23                  INX      H

F_L_0b9d:
$0b9d:  b9                  CMP      C
$0b9e:  ca a9 0b            JZ       $0ba9
$0ba1:  0c                  INR      C
$0ba2:  05                  DCR      B
$0ba3:  c2 9b 0b            JNZ      $0b9b
$0ba6:  c3 54 0b            JMP      $0b54

F_L_0ba9:
$0ba9:  5e                  MOV      E,M
$0baa:  23                  INX      H
$0bab:  56                  MOV      D,M
$0bac:  eb                  XCHG
$0bad:  e9                  PCHL

F_L_0bae:
$0bae:  d5                  PUSH     D
$0baf:  21 2f 0c            LXI      H,$0c2f
$0bb2:  06 30               MVI      B,$30
$0bb4:  0e 01               MVI      C,$01

F_L_0bb6:
$0bb6:  7b                  MOV      A,E
$0bb7:  be                  CMP      M
$0bb8:  23                  INX      H
$0bb9:  c2 be 0b            JNZ      $0bbe
$0bbc:  7a                  MOV      A,D
$0bbd:  be                  CMP      M

F_L_0bbe:
$0bbe:  23                  INX      H
$0bbf:  ca c9 0b            JZ       $0bc9
$0bc2:  0c                  INR      C
$0bc3:  05                  DCR      B
$0bc4:  c2 b6 0b            JNZ      $0bb6
$0bc7:  0e 00               MVI      C,$00

F_L_0bc9:
$0bc9:  2b                  DCX      H
$0bca:  2b                  DCX      H
$0bcb:  5e                  MOV      E,M
$0bcc:  23                  INX      H
$0bcd:  56                  MOV      D,M
$0bce:  eb                  XCHG
$0bcf:  d1                  POP      D
$0bd0:  c9                  RET
$0bd1:  d1                  POP      D
$0bd2:  14                  INR      D
$0bd3:  19                  DAD      D
$0bd4:  15                  DCR      D
$0bd5:  60                  MOV      H,B
$0bd6:  12                  STAX     D
$0bd7:  83                  ADD      E
$0bd8:  12                  STAX     D
$0bd9:  e6 11               ANI      $11
$0bdb:  1a                  LDAX     D
$0bdc:  12                  STAX     D
$0bdd:  58                  MOV      E,B
$0bde:  13                  INX      D
$0bdf:  6b                  MOV      L,E
$0be0:  0e 83               MVI      C,$83
$0be2:  15                  DCR      D
$0be3:  d5                  PUSH     D
$0be4:  15                  DCR      D
$0be5:  27                  DAA
$0be6:  16 7c               MVI      D,$7c
$0be8:  16 d0               MVI      D,$d0
$0bea:  16 b2               MVI      D,$b2
$0bec:  0e 21               MVI      C,$21
$0bee:  17                  RAL
$0bef:  f5                  PUSH     PSW
$0bf0:  0e 09               MVI      C,$09
$0bf2:  0d                  DCR      C
$0bf3:  3f                  CMC
$0bf4:  18                  NOP
$0bf5:  5f                  MOV      E,A
$0bf6:  18                  NOP
$0bf7:  2f                  CMA
$0bf8:  0f                  RRC
$0bf9:  56                  MOV      D,M
$0bfa:  11 21 11            LXI      D,$1121
$0bfd:  45                  MOV      B,L
$0bfe:  11 9e 18            LXI      D,$189e
$0c01:  98                  SBB      B
$0c02:  0f                  RRC
$0c03:  e8                  RPE
$0c04:  10                  NOP
$0c05:  48                  MOV      C,B
$0c06:  16 7b               MVI      D,$7b
$0c08:  13                  INX      D
$0c09:  a4                  ANA      H
$0c0a:  16 17               MVI      D,$17
$0c0c:  14                  INR      D
$0c0d:  cd 0f 7a            CALL     $7a0f
$0c10:  14                  INR      D
$0c11:  f0                  RP
$0c12:  18                  NOP
$0c13:  29                  DAD      H
$0c14:  19                  DAD      D
$0c15:  d3 0c               OUT      $0c
$0c17:  23                  INX      H
$0c18:  14                  INR      D
$0c19:  b7                  ORA      A
$0c1a:  13                  INX      D
$0c1b:  c3 13 45            JMP      $4513
$0c1e:  19           DB  $19
$0c1f:  8d           DB  $8d
$0c20:  0c           DB  $0c
$0c21:  a3           DB  $a3
$0c22:  10           DB  $10
$0c23:  9d           DB  $9d
$0c24:  19           DB  $19
$0c25:  b2           DB  $b2
$0c26:  19           DB  $19
$0c27:  5c           DB  $5c
$0c28:  0e           DB  $0e
$0c29:  d8           DB  $d8
$0c2a:  17           DB  $17
$0c2b:  fc           DB  $fc
$0c2c:  16           DB  $16
$0c2d:  10           DB  $10
$0c2e:  0f           DB  $0f
$0c2f:  41           DB  $41
$0c30:  41           DB  $41
$0c31:  41           DB  $41
$0c32:  52           DB  $52
$0c33:  43           DB  $43
$0c34:  41           DB  $41
$0c35:  49           DB  $49
$0c36:  57           DB  $57
$0c37:  43           DB  $43
$0c38:  49           DB  $49
$0c39:  43           DB  $43
$0c3a:  50           DB  $50
$0c3b:  43           DB  $43
$0c3c:  53           DB  $53
$0c3d:  44           DB  $44
$0c3e:  46           DB  $46
$0c3f:  44           DB  $44
$0c40:  49           DB  $49
$0c41:  44           DB  $44
$0c42:  52           DB  $52
$0c43:  44           DB  $44
$0c44:  54           DB  $54
$0c45:  45           DB  $45
$0c46:  41           DB  $41
$0c47:  45           DB  $45
$0c48:  52           DB  $52
$0c49:  45           DB  $45
$0c4a:  57           DB  $57
$0c4b:  46           DB  $46
$0c4c:  54           DB  $54
$0c4d:  49           DB  $49
$0c4e:  4d           DB  $4d
$0c4f:  49           DB  $49
$0c50:  50           DB  $50
$0c51:  4c           DB  $4c
$0c52:  42           DB  $42
$0c53:  4c           DB  $4c
$0c54:  4f           DB  $4f
$0c55:  4c           DB  $4c
$0c56:  54           DB  $54
$0c57:  50           DB  $50
$0c58:  41           DB  $41
$0c59:  50           DB  $50
$0c5a:  44           DB  $44
$0c5b:  50           DB  $50
$0c5c:  52           DB  $52
$0c5d:  50           DB  $50
$0c5e:  53           DB  $53
$0c5f:  50           DB  $50
$0c60:  54           DB  $54
$0c61:  50           DB  $50
$0c62:  55           DB  $55
$0c63:  52           DB  $52
$0c64:  41           DB  $41
$0c65:  52           DB  $52
$0c66:  4f           DB  $4f
$0c67:  52           DB  $52
$0c68:  52           DB  $52
$0c69:  53           DB  $53
$0c6a:  41           DB  $41
$0c6b:  53           DB  $53
$0c6c:  43           DB  $43
$0c6d:  53           DB  $53
$0c6e:  49           DB  $49
$0c6f:  53           DB  $53
$0c70:  4c           DB  $4c
$0c71:  53           DB  $53
$0c72:  4d           DB  $4d
$0c73:  53           DB  $53
$0c74:  50           DB  $50
$0c75:  53           DB  $53
$0c76:  52           DB  $52
$0c77:  53           DB  $53
$0c78:  53           DB  $53
$0c79:  54           DB  $54
$0c7a:  4c           DB  $4c
$0c7b:  55           DB  $55
$0c7c:  43           DB  $43
$0c7d:  56           DB  $56
$0c7e:  53           DB  $53
$0c7f:  57           DB  $57
$0c80:  47           DB  $47
$0c81:  58           DB  $58
$0c82:  54           DB  $54
$0c83:  59           DB  $59
$0c84:  54           DB  $54
$0c85:  43           DB  $43
$0c86:  43           DB  $43
$0c87:  46           DB  $46
$0c88:  45           DB  $45
$0c89:  45           DB  $45
$0c8a:  53           DB  $53
$0c8b:  49           DB  $49
$0c8c:  4e           DB  $4e
$0c8d:  cd           DB  $cd
$0c8e:  d8           DB  $d8
$0c8f:  19           DB  $19
$0c90:  ca           DB  $ca
$0c91:  ae           DB  $ae
$0c92:  0c           DB  $0c
$0c93:  cd           DB  $cd
$0c94:  4b           DB  $4b
$0c95:  26           DB  $26
$0c96:  cd           DB  $cd
$0c97:  db           DB  $db
$0c98:  19           DB  $19
$0c99:  c2           DB  $c2
$0c9a:  5a           DB  $5a
$0c9b:  0b           DB  $0b
$0c9c:  11           DB  $11
$0c9d:  02           DB  $02
$0c9e:  00           DB  $00
$0c9f:  cd           DB  $cd
$0ca0:  ea           DB  $ea
$0ca1:  27           DB  $27
$0ca2:  da           DB  $da
$0ca3:  ae           DB  $ae
$0ca4:  0c           DB  $0c
$0ca5:  11           DB  $11
$0ca6:  21           DB  $21
$0ca7:  00           DB  $00
$0ca8:  cd           DB  $cd
$0ca9:  ea           DB  $ea
$0caa:  27           DB  $27
$0cab:  da           DB  $da
$0cac:  b0           DB  $b0
$0cad:  0c           DB  $0c
$0cae:  2e           DB  $2e
$0caf:  b4           DB  $b4
$0cb0:  7d           DB  $7d
$0cb1:  fe           DB  $fe
$0cb2:  0a           DB  $0a
$0cb3:  da           DB  $da
$0cb4:  c5           DB  $c5
$0cb5:  0c           DB  $0c
$0cb6:  fe           DB  $fe
$0cb7:  14           DB  $14
$0cb8:  da           DB  $da
$0cb9:  cc           DB  $cc
$0cba:  0c           DB  $0c
$0cbb:  d6           DB  $d6
$0cbc:  0a           DB  $0a
$0cbd:  c6           DB  $c6
$0cbe:  60           DB  $60
$0cbf:  32           DB  $32
$0cc0:  57           DB  $57
$0cc1:  62           DB  $62
$0cc2:  c3           DB  $c3
$0cc3:  5a           DB  $5a
$0cc4:  0b           DB  $0b
$0cc5:  d6           DB  $d6
$0cc6:  02           DB  $02
$0cc7:  c6           DB  $c6
$0cc8:  c0           DB  $c0
$0cc9:  c3           DB  $c3
$0cca:  bf           DB  $bf
$0ccb:  0c           DB  $0c
$0ccc:  d6           DB  $d6
$0ccd:  05           DB  $05
$0cce:  c6           DB  $c6
$0ccf:  a0           DB  $a0
$0cd0:  c3           DB  $c3
$0cd1:  bf           DB  $bf
$0cd2:  0c           DB  $0c
$0cd3:  cd           DB  $cd
$0cd4:  d8           DB  $d8
$0cd5:  19           DB  $19
$0cd6:  ca           DB  $ca
$0cd7:  f8           DB  $f8
$0cd8:  0c           DB  $0c
$0cd9:  32           DB  $32
$0cda:  80           DB  $80
$0cdb:  61           DB  $61
$0cdc:  cd           DB  $cd
$0cdd:  d8           DB  $d8
$0cde:  19           DB  $19
$0cdf:  c2           DB  $c2
$0ce0:  5a           DB  $5a
$0ce1:  0b           DB  $0b
$0ce2:  3a           DB  $3a
$0ce3:  80           DB  $80
$0ce4:  61           DB  $61
$0ce5:  fe           DB  $fe
$0ce6:  31           DB  $31
$0ce7:  da           DB  $da
$0ce8:  5a           DB  $5a
$0ce9:  0b           DB  $0b
$0cea:  fe           DB  $fe
$0ceb:  38           DB  $38
$0cec:  d2           DB  $d2
$0ced:  5a           DB  $5a
$0cee:  0b           DB  $0b
$0cef:  32           DB  $32
$0cf0:  5a           DB  $5a
$0cf1:  62           DB  $62
$0cf2:  cd           DB  $cd
$0cf3:  91           DB  $91
$0cf4:  08           DB  $08
$0cf5:  c3           DB  $c3
$0cf6:  5a           DB  $5a
$0cf7:  0b           DB  $0b
$0cf8:  3a           DB  $3a
$0cf9:  5a           DB  $5a
$0cfa:  62           DB  $62
$0cfb:  fe           DB  $fe
$0cfc:  37           DB  $37
$0cfd:  c2           DB  $c2
$0cfe:  02           DB  $02
$0cff:  0d           DB  $0d
$0d00:  3e           DB  $3e
$0d01:  2f           DB  $2f
$0d02:  3c           DB  $3c
$0d03:  32           DB  $32
$0d04:  5a           DB  $5a
$0d05:  62           DB  $62
$0d06:  c3           DB  $c3
$0d07:  f2           DB  $f2
$0d08:  0c           DB  $0c
$0d09:  cd           DB  $cd
$0d0a:  d8           DB  $d8
$0d0b:  19           DB  $19
$0d0c:  ca           DB  $ca
$0d0d:  20           DB  $20
$0d0e:  0e           DB  $0e
$0d0f:  cd           DB  $cd
$0d10:  4b           DB  $4b
$0d11:  26           DB  $26
$0d12:  cd           DB  $cd
$0d13:  2a           DB  $2a
$0d14:  13           DB  $13
$0d15:  22           DB  $22
$0d16:  80           DB  $80
$0d17:  61           DB  $61
$0d18:  cd           DB  $cd
$0d19:  ca           DB  $ca
$0d1a:  19           DB  $19
$0d1b:  c2           DB  $c2
$0d1c:  5a           DB  $5a
$0d1d:  0b           DB  $0b
$0d1e:  cd           DB  $cd
$0d1f:  48           DB  $48
$0d20:  26           DB  $26
$0d21:  cd           DB  $cd
$0d22:  41           DB  $41
$0d23:  13           DB  $13
$0d24:  22           DB  $22
$0d25:  82           DB  $82
$0d26:  61           DB  $61
$0d27:  cd           DB  $cd
$0d28:  ca           DB  $ca
$0d29:  19           DB  $19
$0d2a:  c2           DB  $c2
$0d2b:  f3           DB  $f3
$0d2c:  0d           DB  $0d
$0d2d:  cd           DB  $cd
$0d2e:  48           DB  $48
$0d2f:  26           DB  $26
$0d30:  cd           DB  $cd
$0d31:  2a           DB  $2a
$0d32:  13           DB  $13
$0d33:  22           DB  $22
$0d34:  84           DB  $84
$0d35:  61           DB  $61
$0d36:  cd           DB  $cd
$0d37:  ca           DB  $ca
$0d38:  19           DB  $19
$0d39:  c2           DB  $c2
$0d3a:  5a           DB  $5a
$0d3b:  0b           DB  $0b
$0d3c:  cd           DB  $cd
$0d3d:  48           DB  $48
$0d3e:  26           DB  $26
$0d3f:  cd           DB  $cd
$0d40:  db           DB  $db
$0d41:  19           DB  $19
$0d42:  c2           DB  $c2
$0d43:  5a           DB  $5a
$0d44:  0b           DB  $0b
$0d45:  cd           DB  $cd
$0d46:  41           DB  $41
$0d47:  13           DB  $13
$0d48:  22           DB  $22
$0d49:  86           DB  $86
$0d4a:  61           DB  $61
$0d4b:  2a           DB  $2a
$0d4c:  80           DB  $80
$0d4d:  61           DB  $61
$0d4e:  eb           DB  $eb
$0d4f:  2a           DB  $2a
$0d50:  84           DB  $84
$0d51:  61           DB  $61
$0d52:  cd           DB  $cd
$0d53:  f0           DB  $f0
$0d54:  27           DB  $27
$0d55:  3a           DB  $3a
$0d56:  8b           DB  $8b
$0d57:  63           DB  $63
$0d58:  d2           DB  $d2
$0d59:  60           DB  $60
$0d5a:  0d           DB  $0d
$0d5b:  f6           DB  $f6
$0d5c:  80           DB  $80
$0d5d:  c3           DB  $c3
$0d5e:  62           DB  $62
$0d5f:  0d           DB  $0d
$0d60:  e6           DB  $e6
$0d61:  7f           DB  $7f
$0d62:  32           DB  $32
$0d63:  8b           DB  $8b
$0d64:  63           DB  $63
$0d65:  22           DB  $22
$0d66:  64           DB  $64
$0d67:  62           DB  $62
$0d68:  2a           DB  $2a
$0d69:  82           DB  $82
$0d6a:  61           DB  $61
$0d6b:  eb           DB  $eb
$0d6c:  2a           DB  $2a
$0d6d:  86           DB  $86
$0d6e:  61           DB  $61
$0d6f:  cd           DB  $cd
$0d70:  f0           DB  $f0
$0d71:  27           DB  $27
$0d72:  3a           DB  $3a
$0d73:  8b           DB  $8b
$0d74:  63           DB  $63
$0d75:  d2           DB  $d2
$0d76:  7d           DB  $7d
$0d77:  0d           DB  $0d
$0d78:  f6           DB  $f6
$0d79:  01           DB  $01
$0d7a:  c3           DB  $c3
$0d7b:  7f           DB  $7f
$0d7c:  0d           DB  $0d
$0d7d:  e6           DB  $e6
$0d7e:  fe           DB  $fe
$0d7f:  32           DB  $32
$0d80:  8b           DB  $8b
$0d81:  63           DB  $63
$0d82:  22           DB  $22
$0d83:  66           DB  $66
$0d84:  62           DB  $62
$0d85:  2a           DB  $2a
$0d86:  87           DB  $87
$0d87:  63           DB  $63
$0d88:  eb           DB  $eb
$0d89:  2a           DB  $2a
$0d8a:  64           DB  $64
$0d8b:  62           DB  $62
$0d8c:  7c           DB  $7c
$0d8d:  a7           DB  $a7
$0d8e:  f2           DB  $f2
$0d8f:  94           DB  $94
$0d90:  0d           DB  $0d
$0d91:  cd           DB  $cd
$0d92:  db           DB  $db
$0d93:  28           DB  $28
$0d94:  cd           DB  $cd
$0d95:  e3           DB  $e3
$0d96:  28           DB  $28
$0d97:  22           DB  $22
$0d98:  91           DB  $91
$0d99:  63           DB  $63
$0d9a:  eb           DB  $eb
$0d9b:  22           DB  $22
$0d9c:  93           DB  $93
$0d9d:  63           DB  $63
$0d9e:  2a           DB  $2a
$0d9f:  89           DB  $89
$0da0:  63           DB  $63
$0da1:  eb           DB  $eb
$0da2:  2a           DB  $2a
$0da3:  66           DB  $66
$0da4:  62           DB  $62
$0da5:  7c           DB  $7c
$0da6:  a7           DB  $a7
$0da7:  f2           DB  $f2
$0da8:  ad           DB  $ad
$0da9:  0d           DB  $0d
$0daa:  cd           DB  $cd
$0dab:  db           DB  $db
$0dac:  28           DB  $28
$0dad:  cd           DB  $cd
$0dae:  e3           DB  $e3
$0daf:  28           DB  $28
$0db0:  22           DB  $22
$0db1:  95           DB  $95
$0db2:  63           DB  $63
$0db3:  eb           DB  $eb
$0db4:  22           DB  $22
$0db5:  97           DB  $97
$0db6:  63           DB  $63
$0db7:  2a           DB  $2a
$0db8:  80           DB  $80
$0db9:  61           DB  $61
$0dba:  eb           DB  $eb
$0dbb:  2a           DB  $2a
$0dbc:  84           DB  $84
$0dbd:  61           DB  $61
$0dbe:  cd           DB  $cd
$0dbf:  ea           DB  $ea
$0dc0:  27           DB  $27
$0dc1:  06           DB  $06
$0dc2:  01           DB  $01
$0dc3:  da           DB  $da
$0dc4:  c8           DB  $c8
$0dc5:  0d           DB  $0d
$0dc6:  eb           DB  $eb
$0dc7:  05           DB  $05
$0dc8:  22           DB  $22
$0dc9:  7b           DB  $7b
$0dca:  63           DB  $63
$0dcb:  eb           DB  $eb
$0dcc:  22           DB  $22
$0dcd:  7f           DB  $7f
$0dce:  63           DB  $63
$0dcf:  2a           DB  $2a
$0dd0:  82           DB  $82
$0dd1:  61           DB  $61
$0dd2:  eb           DB  $eb
$0dd3:  2a           DB  $2a
$0dd4:  86           DB  $86
$0dd5:  61           DB  $61
$0dd6:  cd           DB  $cd
$0dd7:  ea           DB  $ea
$0dd8:  27           DB  $27
$0dd9:  3e           DB  $3e
$0dda:  80           DB  $80
$0ddb:  da           DB  $da
$0ddc:  e0           DB  $e0
$0ddd:  0d           DB  $0d
$0dde:  eb           DB  $eb
$0ddf:  af           DB  $af
$0de0:  b0           DB  $b0
$0de1:  32           DB  $32
$0de2:  ab           DB  $ab
$0de3:  61           DB  $61
$0de4:  22           DB  $22
$0de5:  7d           DB  $7d
$0de6:  63           DB  $63
$0de7:  eb           DB  $eb
$0de8:  22           DB  $22
$0de9:  81           DB  $81
$0dea:  63           DB  $63
$0deb:  3e           DB  $3e
$0dec:  ff           DB  $ff
$0ded:  32           DB  $32
$0dee:  40           DB  $40
$0def:  63           DB  $63
$0df0:  c3           DB  $c3
$0df1:  5a           DB  $5a
$0df2:  0b           DB  $0b
$0df3:  2a           DB  $2a
$0df4:  80           DB  $80
$0df5:  61           DB  $61
$0df6:  eb           DB  $eb
$0df7:  2a           DB  $2a
$0df8:  64           DB  $64
$0df9:  62           DB  $62
$0dfa:  cd           DB  $cd
$0dfb:  bb           DB  $bb
$0dfc:  28           DB  $28
$0dfd:  7c           DB  $7c
$0dfe:  a7           DB  $a7
$0dff:  f2           DB  $f2
$0e00:  05           DB  $05
$0e01:  0e           DB  $0e
$0e02:  21           DB  $21
$0e03:  00           DB  $00
$0e04:  00           DB  $00
$0e05:  22           DB  $22
$0e06:  84           DB  $84
$0e07:  61           DB  $61
$0e08:  2a           DB  $2a
$0e09:  82           DB  $82
$0e0a:  61           DB  $61
$0e0b:  eb           DB  $eb
$0e0c:  2a           DB  $2a
$0e0d:  66           DB  $66
$0e0e:  62           DB  $62
$0e0f:  cd           DB  $cd
$0e10:  bb           DB  $bb
$0e11:  28           DB  $28
$0e12:  7c           DB  $7c
$0e13:  a7           DB  $a7
$0e14:  f2           DB  $f2
$0e15:  1a           DB  $1a
$0e16:  0e           DB  $0e
$0e17:  21           DB  $21
$0e18:  00           DB  $00
$0e19:  00           DB  $00
$0e1a:  22           DB  $22
$0e1b:  86           DB  $86
$0e1c:  61           DB  $61
$0e1d:  c3           DB  $c3
$0e1e:  4b           DB  $4b
$0e1f:  0d           DB  $0d
$0e20:  cd           DB  $cd
$0e21:  26           DB  $26
$0e22:  0e           DB  $0e
$0e23:  c3           DB  $c3
$0e24:  5a           DB  $5a
$0e25:  0b           DB  $0b

F_L_0e26:
$0e26:  3a f0 63            LDA      $63f0
$0e29:  1f                  RAR
$0e2a:  21 a0 41            LXI      H,$41a0
$0e2d:  11 68 2e            LXI      D,$2e68
$0e30:  d2 39 0e            JNC      $0e39
$0e33:  21 68 2e            LXI      H,$2e68
$0e36:  11 d0 20            LXI      D,$20d0

F_L_0e39:
$0e39:  22 87 63            SHLD     $6387
$0e3c:  22 64 62            SHLD     $6264
$0e3f:  eb                  XCHG
$0e40:  22 89 63            SHLD     $6389
$0e43:  22 66 62            SHLD     $6266
$0e46:  21 00 00            LXI      H,$0000
$0e49:  22 91 63            SHLD     $6391
$0e4c:  22 95 63            SHLD     $6395
$0e4f:  23                  INX      H
$0e50:  22 93 63            SHLD     $6393
$0e53:  22 97 63            SHLD     $6397
$0e56:  3e ff               MVI      A,$ff
$0e58:  32 40 63            STA      $6340
$0e5b:  c9                  RET
$0e5c:  cd 48 26            CALL     $2648
$0e5f:  cd db 19            CALL     $19db
$0e62:  c2 5a 0b            JNZ      $0b5a
$0e65:  22 49 61            SHLD     $6149
$0e68:  c3 5a 0b            JMP      $0b5a
$0e6b:  cd           DB  $cd
$0e6c:  d8           DB  $d8
$0e6d:  19           DB  $19
$0e6e:  c2           DB  $c2
$0e6f:  5a           DB  $5a
$0e70:  0b           DB  $0b
$0e71:  cd           DB  $cd
$0e72:  77           DB  $77
$0e73:  0e           DB  $0e
$0e74:  c3           DB  $c3
$0e75:  5a           DB  $5a
$0e76:  0b           DB  $0b

F_L_0e77:
$0e77:  cd c1 15            CALL     $15c1
$0e7a:  cd 17 19            CALL     $1917
$0e7d:  cd b8 14            CALL     $14b8
$0e80:  cd 13 16            CALL     $1613
$0e83:  cd 76 13            CALL     $1376
$0e86:  cd 7e 12            CALL     $127e
$0e89:  cd 21 18            CALL     $1821
$0e8c:  cd 01 13            CALL     $1301
$0e8f:  cd 01 14            CALL     $1401
$0e92:  cd 8d 0f            CALL     $0f8d
$0e95:  cd 9e 10            CALL     $109e
$0e98:  21 0c 00            LXI      H,$000c
$0e9b:  22 36 62            SHLD     $6236
$0e9e:  af                  XRA      A
$0e9f:  32 33 63            STA      $6333
$0ea2:  3e 17               MVI      A,$17
$0ea4:  32 4b 61            STA      $614b
$0ea7:  3e ca               MVI      A,$ca
$0ea9:  32 57 62            STA      $6257
$0eac:  3e 03               MVI      A,$03
$0eae:  32 ed 62            STA      $62ed
$0eb1:  c9                  RET
$0eb2:  cd 48 26            CALL     $2648
$0eb5:  22 cc 61            SHLD     $61cc
$0eb8:  cd ca 19            CALL     $19ca
$0ebb:  c2 5a 0b            JNZ      $0b5a
$0ebe:  cd 48 26            CALL     $2648
$0ec1:  22 30 62            SHLD     $6230
$0ec4:  cd ca 19            CALL     $19ca
$0ec7:  c2 5a 0b            JNZ      $0b5a
$0eca:  cd 48 26            CALL     $2648
$0ecd:  22 ea 61            SHLD     $61ea
$0ed0:  cd ca 19            CALL     $19ca
$0ed3:  ca e4 0e            JZ       $0ee4
$0ed6:  fe 3b               CPI      $3b
$0ed8:  c2 5a 0b            JNZ      $0b5a
$0edb:  21 05 00            LXI      H,$0005
$0ede:  22 ca 61            SHLD     $61ca
$0ee1:  c3 ef 0e            JMP      $0eef

F_L_0ee4:
$0ee4:  cd 4b 26            CALL     $264b
$0ee7:  cd ca 19            CALL     $19ca
$0eea:  fe 3b               CPI      $3b
$0eec:  c2 5a 0b            JNZ      $0b5a

F_L_0eef:
$0eef:  cd 0f 31            CALL     $310f
$0ef2:  c3 5a 0b            JMP      $0b5a
$0ef5:  cd           DB  $cd
$0ef6:  d8           DB  $d8
$0ef7:  19           DB  $19
$0ef8:  ca           DB  $ca
$0ef9:  0b           DB  $0b
$0efa:  0f           DB  $0f
$0efb:  cd           DB  $cd
$0efc:  4b           DB  $4b
$0efd:  26           DB  $26
$0efe:  cd           DB  $cd
$0eff:  db           DB  $db
$0f00:  19           DB  $19
$0f01:  c2           DB  $c2
$0f02:  5a           DB  $5a
$0f03:  0b           DB  $0b
$0f04:  7d           DB  $7d
$0f05:  32           DB  $32
$0f06:  4b           DB  $4b
$0f07:  61           DB  $61
$0f08:  c3           DB  $c3
$0f09:  5a           DB  $5a
$0f0a:  0b           DB  $0b
$0f0b:  3e           DB  $3e
$0f0c:  17           DB  $17
$0f0d:  c3           DB  $c3
$0f0e:  05           DB  $05
$0f0f:  0f           DB  $0f
$0f10:  cd           DB  $cd
$0f11:  77           DB  $77
$0f12:  0e           DB  $0e
$0f13:  af           DB  $af
$0f14:  32           DB  $32
$0f15:  de           DB  $de
$0f16:  63           DB  $63
$0f17:  cd           DB  $cd
$0f18:  26           DB  $26
$0f19:  0e           DB  $0e
$0f1a:  cd           DB  $cd
$0f1b:  7c           DB  $7c
$0f1c:  02           DB  $02
$0f1d:  cd           DB  $cd
$0f1e:  0c           DB  $0c
$0f1f:  11           DB  $11
$0f20:  21           DB  $21
$0f21:  00           DB  $00
$0f22:  00           DB  $00
$0f23:  22           DB  $22
$0f24:  5d           DB  $5d
$0f25:  63           DB  $63
$0f26:  22           DB  $22
$0f27:  5f           DB  $5f
$0f28:  63           DB  $63
$0f29:  cd           DB  $cd
$0f2a:  e0           DB  $e0
$0f2b:  1c           DB  $1c
$0f2c:  c3           DB  $c3
$0f2d:  5a           DB  $5a
$0f2e:  0b           DB  $0b
$0f2f:  cd           DB  $cd
$0f30:  d8           DB  $d8
$0f31:  19           DB  $19
$0f32:  ca           DB  $ca
$0f33:  87           DB  $87
$0f34:  0f           DB  $0f
$0f35:  cd           DB  $cd
$0f36:  4b           DB  $4b
$0f37:  26           DB  $26
$0f38:  cd           DB  $cd
$0f39:  ca           DB  $ca
$0f3a:  19           DB  $19
$0f3b:  7c           DB  $7c
$0f3c:  a7           DB  $a7
$0f3d:  c2           DB  $c2
$0f3e:  76           DB  $76
$0f3f:  0f           DB  $0f
$0f40:  7d           DB  $7d
$0f41:  a7           DB  $a7
$0f42:  ca           DB  $ca
$0f43:  76           DB  $76
$0f44:  0f           DB  $0f
$0f45:  fe           DB  $fe
$0f46:  07           DB  $07
$0f47:  d2           DB  $d2
$0f48:  76           DB  $76
$0f49:  0f           DB  $0f
$0f4a:  f6           DB  $f6
$0f4b:  40           DB  $40
$0f4c:  47           DB  $47
$0f4d:  3a           DB  $3a
$0f4e:  48           DB  $48
$0f4f:  61           DB  $61
$0f50:  fe           DB  $fe
$0f51:  2c           DB  $2c
$0f52:  c2           DB  $c2
$0f53:  7b           DB  $7b
$0f54:  0f           DB  $0f
$0f55:  cd           DB  $cd
$0f56:  f1           DB  $f1
$0f57:  25           DB  $25
$0f58:  cd           DB  $cd
$0f59:  db           DB  $db
$0f5a:  19           DB  $19
$0f5b:  c2           DB  $c2
$0f5c:  5a           DB  $5a
$0f5d:  0b           DB  $0b
$0f5e:  7a           DB  $7a
$0f5f:  a7           DB  $a7
$0f60:  c2           DB  $c2
$0f61:  87           DB  $87
$0f62:  0f           DB  $0f
$0f63:  7b           DB  $7b
$0f64:  a7           DB  $a7
$0f65:  fa           DB  $fa
$0f66:  87           DB  $87
$0f67:  0f           DB  $0f
$0f68:  cd           DB  $cd
$0f69:  c0           DB  $c0
$0f6a:  1c           DB  $1c
$0f6b:  7c           DB  $7c
$0f6c:  b5           DB  $b5
$0f6d:  ca           DB  $ca
$0f6e:  87           DB  $87
$0f6f:  0f           DB  $0f
$0f70:  22           DB  $22
$0f71:  6a           DB  $6a
$0f72:  62           DB  $62
$0f73:  c3           DB  $c3
$0f74:  80           DB  $80
$0f75:  0f           DB  $0f
$0f76:  06           DB  $06
$0f77:  00           DB  $00
$0f78:  3a           DB  $3a
$0f79:  48           DB  $48
$0f7a:  61           DB  $61
$0f7b:  fe           DB  $fe
$0f7c:  3b           DB  $3b
$0f7d:  c2           DB  $c2
$0f7e:  5a           DB  $5a
$0f7f:  0b           DB  $0b
$0f80:  78           DB  $78
$0f81:  32           DB  $32
$0f82:  68           DB  $68
$0f83:  62           DB  $62
$0f84:  c3           DB  $c3
$0f85:  5a           DB  $5a
$0f86:  0b           DB  $0b
$0f87:  cd           DB  $cd
$0f88:  8d           DB  $8d
$0f89:  0f           DB  $0f
$0f8a:  c3           DB  $c3
$0f8b:  5a           DB  $5a
$0f8c:  0b           DB  $0b

F_L_0f8d:
$0f8d:  af                  XRA      A
$0f8e:  32 68 62            STA      $6268
$0f91:  21 0a 00            LXI      H,$000a
$0f94:  22 6a 62            SHLD     $626a
$0f97:  c9                  RET
$0f98:  cd d8 19            CALL     $19d8
$0f9b:  ca c4 0f            JZ       $0fc4
$0f9e:  cd f4 25            CALL     $25f4
$0fa1:  cd db 19            CALL     $19db
$0fa4:  c2 5a 0b            JNZ      $0b5a
$0fa7:  7a                  MOV      A,D
$0fa8:  b3                  ORA      E
$0fa9:  c2 5a 0b            JNZ      $0b5a
$0fac:  11 28 00            LXI      D,$0028
$0faf:  cd 57 29            CALL     $2957
$0fb2:  11 08 00            LXI      D,$0008
$0fb5:  cd ea 27            CALL     $27ea
$0fb8:  da c4 0f            JC       $0fc4
$0fbb:  11 21 00            LXI      D,$0021
$0fbe:  cd ea 27            CALL     $27ea
$0fc1:  da c7 0f            JC       $0fc7

F_L_0fc4:
$0fc4:  21 0c 00            LXI      H,$000c

F_L_0fc7:
$0fc7:  22 36 62            SHLD     $6236
$0fca:  c3 5a 0b            JMP      $0b5a
$0fcd:  cd           DB  $cd
$0fce:  d8           DB  $d8
$0fcf:  19           DB  $19
$0fd0:  ca           DB  $ca
$0fd1:  98           DB  $98
$0fd2:  10           DB  $10
$0fd3:  cd           DB  $cd
$0fd4:  f4           DB  $f4
$0fd5:  25           DB  $25
$0fd6:  cd           DB  $cd
$0fd7:  ca           DB  $ca
$0fd8:  19           DB  $19
$0fd9:  c2           DB  $c2
$0fda:  5a           DB  $5a
$0fdb:  0b           DB  $0b
$0fdc:  22           DB  $22
$0fdd:  80           DB  $80
$0fde:  61           DB  $61
$0fdf:  eb           DB  $eb
$0fe0:  22           DB  $22
$0fe1:  82           DB  $82
$0fe2:  61           DB  $61
$0fe3:  cd           DB  $cd
$0fe4:  f1           DB  $f1
$0fe5:  25           DB  $25
$0fe6:  cd           DB  $cd
$0fe7:  ca           DB  $ca
$0fe8:  19           DB  $19
$0fe9:  c2           DB  $c2
$0fea:  5a           DB  $5a
$0feb:  0b           DB  $0b
$0fec:  22           DB  $22
$0fed:  84           DB  $84
$0fee:  61           DB  $61
$0fef:  eb           DB  $eb
$0ff0:  22           DB  $22
$0ff1:  86           DB  $86
$0ff2:  61           DB  $61
$0ff3:  cd           DB  $cd
$0ff4:  f1           DB  $f1
$0ff5:  25           DB  $25
$0ff6:  cd           DB  $cd
$0ff7:  ca           DB  $ca
$0ff8:  19           DB  $19
$0ff9:  c2           DB  $c2
$0ffa:  5a           DB  $5a
$0ffb:  0b           DB  $0b
$0ffc:  22           DB  $22
$0ffd:  88           DB  $88
$0ffe:  61           DB  $61
$0fff:  eb           DB  $eb
$1000:  22           DB  $22
$1001:  8a           DB  $8a
$1002:  61           DB  $61
$1003:  cd           DB  $cd
$1004:  f1           DB  $f1
$1005:  25           DB  $25
$1006:  cd           DB  $cd
$1007:  db           DB  $db
$1008:  19           DB  $19
$1009:  c2           DB  $c2
$100a:  5a           DB  $5a
$100b:  0b           DB  $0b
$100c:  22           DB  $22
$100d:  8c           DB  $8c
$100e:  61           DB  $61
$100f:  eb           DB  $eb
$1010:  22           DB  $22
$1011:  8e           DB  $8e
$1012:  61           DB  $61
$1013:  21           DB  $21
$1014:  80           DB  $80
$1015:  61           DB  $61
$1016:  11           DB  $11
$1017:  84           DB  $84
$1018:  61           DB  $61
$1019:  cd           DB  $cd
$101a:  e6           DB  $e6
$101b:  2b           DB  $2b
$101c:  ca           DB  $ca
$101d:  8c           DB  $8c
$101e:  10           DB  $10
$101f:  21           DB  $21
$1020:  88           DB  $88
$1021:  61           DB  $61
$1022:  11           DB  $11
$1023:  8c           DB  $8c
$1024:  61           DB  $61
$1025:  cd           DB  $cd
$1026:  e6           DB  $e6
$1027:  2b           DB  $2b
$1028:  ca           DB  $ca
$1029:  8c           DB  $8c
$102a:  10           DB  $10
$102b:  11           DB  $11
$102c:  ae           DB  $ae
$102d:  61           DB  $61
$102e:  21           DB  $21
$102f:  80           DB  $80
$1030:  61           DB  $61
$1031:  cd           DB  $cd
$1032:  11           DB  $11
$1033:  2c           DB  $2c
$1034:  11           DB  $11
$1035:  b2           DB  $b2
$1036:  61           DB  $61
$1037:  21           DB  $21
$1038:  88           DB  $88
$1039:  61           DB  $61
$103a:  cd           DB  $cd
$103b:  11           DB  $11
$103c:  2c           DB  $2c
$103d:  21           DB  $21
$103e:  80           DB  $80
$103f:  61           DB  $61
$1040:  11           DB  $11
$1041:  84           DB  $84
$1042:  61           DB  $61
$1043:  cd           DB  $cd
$1044:  41           DB  $41
$1045:  2b           DB  $2b
$1046:  21           DB  $21
$1047:  88           DB  $88
$1048:  61           DB  $61
$1049:  11           DB  $11
$104a:  8c           DB  $8c
$104b:  61           DB  $61
$104c:  cd           DB  $cd
$104d:  41           DB  $41
$104e:  2b           DB  $2b
$104f:  21           DB  $21
$1050:  00           DB  $00
$1051:  00           DB  $00
$1052:  22           DB  $22
$1053:  80           DB  $80
$1054:  61           DB  $61
$1055:  22           DB  $22
$1056:  88           DB  $88
$1057:  61           DB  $61
$1058:  2a           DB  $2a
$1059:  64           DB  $64
$105a:  62           DB  $62
$105b:  22           DB  $22
$105c:  82           DB  $82
$105d:  61           DB  $61
$105e:  2a           DB  $2a
$105f:  66           DB  $66
$1060:  62           DB  $62
$1061:  22           DB  $22
$1062:  8a           DB  $8a
$1063:  61           DB  $61
$1064:  11           DB  $11
$1065:  80           DB  $80
$1066:  61           DB  $61
$1067:  21           DB  $21
$1068:  84           DB  $84
$1069:  61           DB  $61
$106a:  cd           DB  $cd
$106b:  f1           DB  $f1
$106c:  29           DB  $29
$106d:  22           DB  $22
$106e:  b6           DB  $b6
$106f:  61           DB  $61
$1070:  eb           DB  $eb
$1071:  22           DB  $22
$1072:  b8           DB  $b8
$1073:  61           DB  $61
$1074:  11           DB  $11
$1075:  88           DB  $88
$1076:  61           DB  $61
$1077:  21           DB  $21
$1078:  8c           DB  $8c
$1079:  61           DB  $61
$107a:  cd           DB  $cd
$107b:  f1           DB  $f1
$107c:  29           DB  $29
$107d:  22           DB  $22
$107e:  ba           DB  $ba
$107f:  61           DB  $61
$1080:  eb           DB  $eb
$1081:  22           DB  $22
$1082:  bc           DB  $bc
$1083:  61           DB  $61
$1084:  3e           DB  $3e
$1085:  80           DB  $80
$1086:  32           DB  $32
$1087:  ac           DB  $ac
$1088:  61           DB  $61
$1089:  c3           DB  $c3
$108a:  5a           DB  $5a
$108b:  0b           DB  $0b
$108c:  3e           DB  $3e
$108d:  03           DB  $03
$108e:  21           DB  $21
$108f:  4b           DB  $4b
$1090:  61           DB  $61
$1091:  a6           DB  $a6
$1092:  32           DB  $32
$1093:  de           DB  $de
$1094:  63           DB  $63
$1095:  c3           DB  $c3
$1096:  5a           DB  $5a
$1097:  0b           DB  $0b
$1098:  cd           DB  $cd
$1099:  9e           DB  $9e
$109a:  10           DB  $10
$109b:  c3           DB  $c3
$109c:  5a           DB  $5a
$109d:  0b           DB  $0b

F_L_109e:
$109e:  af                  XRA      A
$109f:  32 ac 61            STA      $61ac
$10a2:  c9                  RET
$10a3:  0e 00               MVI      C,$00
$10a5:  cd 87 25            CALL     $2587
$10a8:  22 cc 61            SHLD     $61cc
$10ab:  cd ca 19            CALL     $19ca
$10ae:  c2 5a 0b            JNZ      $0b5a
$10b1:  cd 48 26            CALL     $2648
$10b4:  22 30 62            SHLD     $6230
$10b7:  cd ca 19            CALL     $19ca
$10ba:  c2 5a 0b            JNZ      $0b5a
$10bd:  cd 4b 26            CALL     $264b
$10c0:  22 ea 61            SHLD     $61ea
$10c3:  cd ca 19            CALL     $19ca
$10c6:  ca d7 10            JZ       $10d7
$10c9:  fe 3b               CPI      $3b
$10cb:  c2 5a 0b            JNZ      $0b5a
$10ce:  21 05 00            LXI      H,$0005
$10d1:  22 ca 61            SHLD     $61ca
$10d4:  c3 e2 10            JMP      $10e2

F_L_10d7:
$10d7:  cd 4b 26            CALL     $264b
$10da:  cd ca 19            CALL     $19ca
$10dd:  fe 3b               CPI      $3b
$10df:  c2 5a 0b            JNZ      $0b5a

F_L_10e2:
$10e2:  cd 0f 31            CALL     $310f
$10e5:  c3 5a 0b            JMP      $0b5a
$10e8:  cd           DB  $cd
$10e9:  d8           DB  $d8
$10ea:  19           DB  $19
$10eb:  3e           DB  $3e
$10ec:  00           DB  $00
$10ed:  c2           DB  $c2
$10ee:  64           DB  $64
$10ef:  11           DB  $11
$10f0:  32           DB  $32
$10f1:  2e           DB  $2e
$10f2:  63           DB  $63
$10f3:  32           DB  $32
$10f4:  5b           DB  $5b
$10f5:  62           DB  $62
$10f6:  3a           DB  $3a
$10f7:  f0           DB  $f0
$10f8:  63           DB  $63
$10f9:  e6           DB  $e6
$10fa:  02           DB  $02
$10fb:  ca           DB  $ca
$10fc:  5a           DB  $5a
$10fd:  0b           DB  $0b
$10fe:  3a           DB  $3a
$10ff:  00           DB  $00
$1100:  e0           DB  $e0
$1101:  e6           DB  $e6
$1102:  40           DB  $40
$1103:  ca           DB  $ca
$1104:  fe           DB  $fe
$1105:  10           DB  $10
$1106:  cd           DB  $cd
$1107:  3c           DB  $3c
$1108:  22           DB  $22
$1109:  c3           DB  $c3
$110a:  5a           DB  $5a
$110b:  0b           DB  $0b

F_L_110c:
$110c:  f5                  PUSH     PSW
$110d:  af                  XRA      A
$110e:  32 2f 63            STA      $632f
$1111:  32 5b 62            STA      $625b
$1114:  f1                  POP      PSW
$1115:  c9                  RET

F_L_1116:
$1116:  f5                  PUSH     PSW
$1117:  3e ff               MVI      A,$ff
$1119:  32 2f 63            STA      $632f
$111c:  32 5b 62            STA      $625b
$111f:  f1                  POP      PSW
$1120:  c9                  RET
$1121:  cd d8 19            CALL     $19d8
$1124:  3e ff               MVI      A,$ff
$1126:  c2 64 11            JNZ      $1164
$1129:  32 5b 62            STA      $625b
$112c:  32 2e 63            STA      $632e
$112f:  3a f0 63            LDA      $63f0
$1132:  e6 02               ANI      $02
$1134:  c2 5a 0b            JNZ      $0b5a

F_L_1137:
$1137:  3a 00 e0            LDA      $e000
$113a:  e6 40               ANI      $40
$113c:  ca 37 11            JZ       $1137
$113f:  cd 16 22            CALL     $2216
$1142:  c3 5a 0b            JMP      $0b5a
$1145:  3a           DB  $3a
$1146:  8b           DB  $8b
$1147:  63           DB  $63
$1148:  f6           DB  $f6
$1149:  02           DB  $02
$114a:  32           DB  $32
$114b:  8b           DB  $8b
$114c:  63           DB  $63
$114d:  cd           DB  $cd
$114e:  c7           DB  $c7
$114f:  19           DB  $19
$1150:  ca           DB  $ca
$1151:  5a           DB  $5a
$1152:  0b           DB  $0b
$1153:  c3           DB  $c3
$1154:  61           DB  $61
$1155:  11           DB  $11
$1156:  3a           DB  $3a
$1157:  8b           DB  $8b
$1158:  63           DB  $63
$1159:  e6           DB  $e6
$115a:  fd           DB  $fd
$115b:  32           DB  $32
$115c:  8b           DB  $8b
$115d:  63           DB  $63

F_L_115e:
$115e:  cd c7 19            CALL     $19c7
$1161:  3a 2e 63            LDA      $632e

F_L_1164:
$1164:  32 2e 63            STA      $632e
$1167:  32 5b 62            STA      $625b
$116a:  32 2f 63            STA      $632f
$116d:  06 00               MVI      B,$00
$116f:  cd 8a 25            CALL     $258a
$1172:  22 5d 63            SHLD     $635d
$1175:  cd ca 19            CALL     $19ca
$1178:  c2 5a 0b            JNZ      $0b5a
$117b:  0e 0f               MVI      C,$0f
$117d:  cd 87 25            CALL     $2587
$1180:  22 5f 63            SHLD     $635f
$1183:  cd ca 19            CALL     $19ca
$1186:  c2 b5 11            JNZ      $11b5
$1189:  cd e0 1c            CALL     $1ce0
$118c:  3a 33 63            LDA      $6333
$118f:  a7                  ANA      A
$1190:  ca 5e 11            JZ       $115e
$1193:  3a ec 62            LDA      $62ec
$1196:  e6 03               ANI      $03
$1198:  f6 08               ORI      $08
$119a:  32 ec 62            STA      $62ec
$119d:  cd 7c 02            CALL     $027c
$11a0:  cd 0c 11            CALL     $110c
$11a3:  cd 65 02            CALL     $0265
$11a6:  3a 33 63            LDA      $6333
$11a9:  cd c0 3a            CALL     $3ac0
$11ac:  cd 73 02            CALL     $0273
$11af:  cd 88 02            CALL     $0288
$11b2:  c3 5e 11            JMP      $115e

F_L_11b5:
$11b5:  fe 3b               CPI      $3b
$11b7:  c2 5a 0b            JNZ      $0b5a
$11ba:  cd e0 1c            CALL     $1ce0
$11bd:  3a 33 63            LDA      $6333
$11c0:  a7                  ANA      A
$11c1:  ca 5a 0b            JZ       $0b5a
$11c4:  3a ec 62            LDA      $62ec
$11c7:  e6 03               ANI      $03
$11c9:  f6 08               ORI      $08
$11cb:  32 ec 62            STA      $62ec
$11ce:  cd 7c 02            CALL     $027c
$11d1:  cd 0c 11            CALL     $110c
$11d4:  3a 33 63            LDA      $6333
$11d7:  cd 65 02            CALL     $0265
$11da:  cd c0 3a            CALL     $3ac0
$11dd:  cd 73 02            CALL     $0273
$11e0:  cd 88 02            CALL     $0288
$11e3:  c3 5a 0b            JMP      $0b5a
$11e6:  cd           DB  $cd
$11e7:  d8           DB  $d8
$11e8:  19           DB  $19
$11e9:  ca           DB  $ca
$11ea:  5a           DB  $5a
$11eb:  0b           DB  $0b
$11ec:  21           DB  $21
$11ed:  05           DB  $05
$11ee:  00           DB  $00
$11ef:  22           DB  $22
$11f0:  ca           DB  $ca
$11f1:  61           DB  $61
$11f2:  0e           DB  $0e
$11f3:  00           DB  $00
$11f4:  cd           DB  $cd
$11f5:  8a           DB  $8a
$11f6:  25           DB  $25
$11f7:  22           DB  $22
$11f8:  cc           DB  $cc
$11f9:  61           DB  $61
$11fa:  cd           DB  $cd
$11fb:  ca           DB  $ca
$11fc:  19           DB  $19
$11fd:  c2           DB  $c2
$11fe:  09           DB  $09
$11ff:  12           DB  $12
$1200:  cd           DB  $cd
$1201:  48           DB  $48
$1202:  26           DB  $26
$1203:  22           DB  $22
$1204:  ca           DB  $ca
$1205:  61           DB  $61
$1206:  cd           DB  $cd
$1207:  ca           DB  $ca
$1208:  19           DB  $19
$1209:  fe           DB  $fe
$120a:  3b           DB  $3b
$120b:  c2           DB  $c2
$120c:  5a           DB  $5a
$120d:  0b           DB  $0b
$120e:  cd           DB  $cd
$120f:  7c           DB  $7c
$1210:  02           DB  $02
$1211:  cd           DB  $cd
$1212:  1f           DB  $1f
$1213:  39           DB  $39
$1214:  cd           DB  $cd
$1215:  88           DB  $88
$1216:  02           DB  $02
$1217:  c3           DB  $c3
$1218:  5a           DB  $5a
$1219:  0b           DB  $0b
$121a:  cd           DB  $cd
$121b:  d8           DB  $d8
$121c:  19           DB  $19
$121d:  ca           DB  $ca
$121e:  54           DB  $54
$121f:  12           DB  $12
$1220:  cd           DB  $cd
$1221:  4b           DB  $4b
$1222:  26           DB  $26
$1223:  cd           DB  $cd
$1224:  ca           DB  $ca
$1225:  19           DB  $19
$1226:  c2           DB  $c2
$1227:  5a           DB  $5a
$1228:  0b           DB  $0b
$1229:  22           DB  $22
$122a:  82           DB  $82
$122b:  62           DB  $62
$122c:  cd           DB  $cd
$122d:  48           DB  $48
$122e:  26           DB  $26
$122f:  cd           DB  $cd
$1230:  db           DB  $db
$1231:  19           DB  $19
$1232:  c2           DB  $c2
$1233:  5a           DB  $5a
$1234:  0b           DB  $0b
$1235:  22           DB  $22
$1236:  84           DB  $84
$1237:  62           DB  $62
$1238:  3a           DB  $3a
$1239:  ec           DB  $ec
$123a:  62           DB  $62
$123b:  e6           DB  $e6
$123c:  03           DB  $03
$123d:  f6           DB  $f6
$123e:  0c           DB  $0c
$123f:  32           DB  $32
$1240:  ec           DB  $ec
$1241:  62           DB  $62
$1242:  cd           DB  $cd
$1243:  7c           DB  $7c
$1244:  02           DB  $02
$1245:  cd           DB  $cd
$1246:  65           DB  $65
$1247:  02           DB  $02
$1248:  cd           DB  $cd
$1249:  c0           DB  $c0
$124a:  3a           DB  $3a
$124b:  cd           DB  $cd
$124c:  73           DB  $73
$124d:  02           DB  $02
$124e:  cd           DB  $cd
$124f:  88           DB  $88
$1250:  02           DB  $02
$1251:  c3           DB  $c3
$1252:  5a           DB  $5a
$1253:  0b           DB  $0b
$1254:  21           DB  $21
$1255:  00           DB  $00
$1256:  00           DB  $00
$1257:  22           DB  $22
$1258:  82           DB  $82
$1259:  62           DB  $62
$125a:  22           DB  $22
$125b:  84           DB  $84
$125c:  62           DB  $62
$125d:  c3           DB  $c3
$125e:  38           DB  $38
$125f:  12           DB  $12
$1260:  cd           DB  $cd
$1261:  d8           DB  $d8
$1262:  19           DB  $19
$1263:  ca           DB  $ca
$1264:  78           DB  $78
$1265:  12           DB  $12
$1266:  cd           DB  $cd
$1267:  4b           DB  $4b
$1268:  26           DB  $26
$1269:  7c           DB  $7c
$126a:  a7           DB  $a7
$126b:  c2           DB  $c2
$126c:  5a           DB  $5a
$126d:  0b           DB  $0b
$126e:  7d           DB  $7d
$126f:  32           DB  $32
$1270:  91           DB  $91
$1271:  62           DB  $62
$1272:  cd           DB  $cd
$1273:  cd           DB  $cd
$1274:  44           DB  $44
$1275:  c3           DB  $c3
$1276:  5a           DB  $5a
$1277:  0b           DB  $0b
$1278:  cd           DB  $cd
$1279:  7e           DB  $7e
$127a:  12           DB  $12
$127b:  c3           DB  $c3
$127c:  5a           DB  $5a
$127d:  0b           DB  $0b

F_L_127e:
$127e:  af                  XRA      A
$127f:  cd cd 44            CALL     $44cd
$1282:  c9                  RET
$1283:  cd d8 19            CALL     $19d8
$1286:  ca cb 12            JZ       $12cb
$1289:  cd 4b 26            CALL     $264b
$128c:  cd 2a 13            CALL     $132a
$128f:  22 80 61            SHLD     $6180
$1292:  cd ca 19            CALL     $19ca
$1295:  c2 5a 0b            JNZ      $0b5a
$1298:  cd 48 26            CALL     $2648
$129b:  cd 41 13            CALL     $1341
$129e:  22 82 61            SHLD     $6182
$12a1:  cd ca 19            CALL     $19ca
$12a4:  c2 5a 0b            JNZ      $0b5a
$12a7:  cd 48 26            CALL     $2648
$12aa:  cd 2a 13            CALL     $132a
$12ad:  22 84 61            SHLD     $6184
$12b0:  cd ca 19            CALL     $19ca
$12b3:  c2 5a 0b            JNZ      $0b5a
$12b6:  cd 48 26            CALL     $2648
$12b9:  cd db 19            CALL     $19db
$12bc:  c2 5a 0b            JNZ      $0b5a
$12bf:  cd 41 13            CALL     $1341
$12c2:  22 86 61            SHLD     $6186
$12c5:  cd d1 12            CALL     $12d1
$12c8:  c3 5a 0b            JMP      $0b5a

F_L_12cb:
$12cb:  cd 01 13            CALL     $1301
$12ce:  c3 5a 0b            JMP      $0b5a

F_L_12d1:
$12d1:  2a 80 61            LHLD     $6180
$12d4:  eb                  XCHG
$12d5:  2a 84 61            LHLD     $6184
$12d8:  cd ea 27            CALL     $27ea
$12db:  d2 df 12            JNC      $12df
$12de:  eb                  XCHG

F_L_12df:
$12df:  22 6d 63            SHLD     $636d
$12e2:  eb                  XCHG
$12e3:  22 69 63            SHLD     $6369
$12e6:  2a 82 61            LHLD     $6182
$12e9:  eb                  XCHG
$12ea:  2a 86 61            LHLD     $6186
$12ed:  cd ea 27            CALL     $27ea
$12f0:  d2 f4 12            JNC      $12f4
$12f3:  eb                  XCHG

F_L_12f4:
$12f4:  22 6f 63            SHLD     $636f
$12f7:  eb                  XCHG
$12f8:  22 6b 63            SHLD     $636b
$12fb:  3e ff               MVI      A,$ff
$12fd:  32 40 63            STA      $6340
$1300:  c9                  RET

F_L_1301:
$1301:  21 00 00            LXI      H,$0000
$1304:  22 69 63            SHLD     $6369
$1307:  22 6b 63            SHLD     $636b
$130a:  3a f0 63            LDA      $63f0
$130d:  1f                  RAR
$130e:  21 68 2e            LXI      H,$2e68
$1311:  11 d0 20            LXI      D,$20d0
$1314:  da 1d 13            JC       $131d
$1317:  21 a0 41            LXI      H,$41a0
$131a:  11 68 2e            LXI      D,$2e68

F_L_131d:
$131d:  22 6d 63            SHLD     $636d
$1320:  eb                  XCHG
$1321:  22 6f 63            SHLD     $636f
$1324:  3e ff               MVI      A,$ff
$1326:  32 40 63            STA      $6340
$1329:  c9                  RET

F_L_132a:
$132a:  7c                  MOV      A,H
$132b:  a7                  ANA      A
$132c:  f2 32 13            JP       $1332
$132f:  21 00 00            LXI      H,$0000

F_L_1332:
$1332:  eb                  XCHG
$1333:  2a 87 63            LHLD     $6387
$1336:  cd ea 27            CALL     $27ea
$1339:  da 3d 13            JC       $133d
$133c:  eb                  XCHG

F_L_133d:
$133d:  3a 48 61            LDA      $6148
$1340:  c9                  RET

F_L_1341:
$1341:  7c                  MOV      A,H
$1342:  a7                  ANA      A
$1343:  f2 49 13            JP       $1349
$1346:  21 00 00            LXI      H,$0000

F_L_1349:
$1349:  eb                  XCHG
$134a:  2a 89 63            LHLD     $6389
$134d:  cd ea 27            CALL     $27ea
$1350:  da 54 13            JC       $1354
$1353:  eb                  XCHG

F_L_1354:
$1354:  3a 48 61            LDA      $6148
$1357:  c9                  RET
$1358:  cd d8 19            CALL     $19d8
$135b:  ca 70 13            JZ       $1370
$135e:  cd 4b 26            CALL     $264b
$1361:  7c                  MOV      A,H
$1362:  a7                  ANA      A
$1363:  c2 5a 0b            JNZ      $0b5a
$1366:  7d                  MOV      A,L
$1367:  32 90 62            STA      $6290
$136a:  cd bc 44            CALL     $44bc
$136d:  c3 5a 0b            JMP      $0b5a

F_L_1370:
$1370:  cd 76 13            CALL     $1376
$1373:  c3 5a 0b            JMP      $0b5a

F_L_1376:
$1376:  af                  XRA      A
$1377:  cd bc 44            CALL     $44bc
$137a:  c9                  RET
$137b:  cd d8 19            CALL     $19d8
$137e:  ca 9f 13            JZ       $139f
$1381:  cd 4b 26            CALL     $264b
$1384:  cd db 19            CALL     $19db
$1387:  c2 5a 0b            JNZ      $0b5a
$138a:  3a 8b 63            LDA      $638b
$138d:  47                  MOV      B,A
$138e:  11 5a 00            LXI      D,$005a
$1391:  cd ea 27            CALL     $27ea
$1394:  3e 04               MVI      A,$04
$1396:  ca ac 13            JZ       $13ac
$1399:  11 00 00            LXI      D,$0000
$139c:  cd ea 27            CALL     $27ea

F_L_139f:
$139f:  3e fb               MVI      A,$fb
$13a1:  ca b0 13            JZ       $13b0
$13a4:  3e 03               MVI      A,$03
$13a6:  32 de 63            STA      $63de
$13a9:  c3 5a 0b            JMP      $0b5a

F_L_13ac:
$13ac:  b0                  ORA      B
$13ad:  c3 b1 13            JMP      $13b1

F_L_13b0:
$13b0:  a0                  ANA      B

F_L_13b1:
$13b1:  32 8b 63            STA      $638b
$13b4:  c3 5a 0b            JMP      $0b5a
$13b7:  cd           DB  $cd
$13b8:  d8           DB  $d8
$13b9:  19           DB  $19
$13ba:  c2           DB  $c2
$13bb:  5a           DB  $5a
$13bc:  0b           DB  $0b
$13bd:  cd           DB  $cd
$13be:  e5           DB  $e5
$13bf:  44           DB  $44
$13c0:  c3           DB  $c3
$13c1:  5a           DB  $5a
$13c2:  0b           DB  $0b
$13c3:  cd           DB  $cd
$13c4:  d8           DB  $d8
$13c5:  19           DB  $19
$13c6:  ca           DB  $ca
$13c7:  fb           DB  $fb
$13c8:  13           DB  $13
$13c9:  cd           DB  $cd
$13ca:  f4           DB  $f4
$13cb:  25           DB  $25
$13cc:  cd           DB  $cd
$13cd:  ca           DB  $ca
$13ce:  19           DB  $19
$13cf:  c2           DB  $c2
$13d0:  5a           DB  $5a
$13d1:  0b           DB  $0b
$13d2:  22           DB  $22
$13d3:  84           DB  $84
$13d4:  61           DB  $61
$13d5:  eb           DB  $eb
$13d6:  22           DB  $22
$13d7:  86           DB  $86
$13d8:  61           DB  $61
$13d9:  cd           DB  $cd
$13da:  f1           DB  $f1
$13db:  25           DB  $25
$13dc:  cd           DB  $cd
$13dd:  db           DB  $db
$13de:  19           DB  $19
$13df:  c2           DB  $c2
$13e0:  5a           DB  $5a
$13e1:  0b           DB  $0b
$13e2:  22           DB  $22
$13e3:  8c           DB  $8c
$13e4:  62           DB  $62
$13e5:  eb           DB  $eb
$13e6:  22           DB  $22
$13e7:  8e           DB  $8e
$13e8:  62           DB  $62
$13e9:  2a           DB  $2a
$13ea:  84           DB  $84
$13eb:  61           DB  $61
$13ec:  22           DB  $22
$13ed:  88           DB  $88
$13ee:  62           DB  $62
$13ef:  2a           DB  $2a
$13f0:  86           DB  $86
$13f1:  61           DB  $61
$13f2:  22           DB  $22
$13f3:  8a           DB  $8a
$13f4:  62           DB  $62
$13f5:  cd           DB  $cd
$13f6:  d2           DB  $d2
$13f7:  41           DB  $41
$13f8:  c3           DB  $c3
$13f9:  5a           DB  $5a
$13fa:  0b           DB  $0b
$13fb:  cd           DB  $cd
$13fc:  01           DB  $01
$13fd:  14           DB  $14
$13fe:  c3           DB  $c3
$13ff:  5a           DB  $5a
$1400:  0b           DB  $0b

F_L_1401:
$1401:  21 00 00            LXI      H,$0000
$1404:  22 8a 62            SHLD     $628a
$1407:  22 8e 62            SHLD     $628e
$140a:  21 00 80            LXI      H,$8000
$140d:  22 88 62            SHLD     $6288
$1410:  22 8c 62            SHLD     $628c
$1413:  cd d2 41            CALL     $41d2
$1416:  c9                  RET
$1417:  cd d8 19            CALL     $19d8
$141a:  c2 5a 0b            JNZ      $0b5a
$141d:  cd de 44            CALL     $44de
$1420:  c3 5a 0b            JMP      $0b5a
$1423:  cd           DB  $cd
$1424:  d8           DB  $d8
$1425:  19           DB  $19
$1426:  ca           DB  $ca
$1427:  5b           DB  $5b
$1428:  14           DB  $14
$1429:  cd           DB  $cd
$142a:  f4           DB  $f4
$142b:  25           DB  $25
$142c:  cd           DB  $cd
$142d:  ca           DB  $ca
$142e:  19           DB  $19
$142f:  c2           DB  $c2
$1430:  5a           DB  $5a
$1431:  0b           DB  $0b
$1432:  22           DB  $22
$1433:  84           DB  $84
$1434:  61           DB  $61
$1435:  eb           DB  $eb
$1436:  22           DB  $22
$1437:  86           DB  $86
$1438:  61           DB  $61
$1439:  cd           DB  $cd
$143a:  f1           DB  $f1
$143b:  25           DB  $25
$143c:  cd           DB  $cd
$143d:  db           DB  $db
$143e:  19           DB  $19
$143f:  c2           DB  $c2
$1440:  5a           DB  $5a
$1441:  0b           DB  $0b
$1442:  22           DB  $22
$1443:  8c           DB  $8c
$1444:  62           DB  $62
$1445:  eb           DB  $eb
$1446:  22           DB  $22
$1447:  8e           DB  $8e
$1448:  62           DB  $62
$1449:  2a           DB  $2a
$144a:  84           DB  $84
$144b:  61           DB  $61
$144c:  22           DB  $22
$144d:  88           DB  $88
$144e:  62           DB  $62
$144f:  2a           DB  $2a
$1450:  86           DB  $86
$1451:  61           DB  $61
$1452:  22           DB  $22
$1453:  8a           DB  $8a
$1454:  62           DB  $62
$1455:  cd           DB  $cd
$1456:  ca           DB  $ca
$1457:  42           DB  $42
$1458:  c3           DB  $c3
$1459:  5a           DB  $5a
$145a:  0b           DB  $0b
$145b:  cd           DB  $cd
$145c:  61           DB  $61
$145d:  14           DB  $14
$145e:  c3           DB  $c3
$145f:  5a           DB  $5a
$1460:  0b           DB  $0b
$1461:  21           DB  $21
$1462:  00           DB  $00
$1463:  00           DB  $00
$1464:  22           DB  $22
$1465:  8a           DB  $8a
$1466:  62           DB  $62
$1467:  22           DB  $22
$1468:  8e           DB  $8e
$1469:  62           DB  $62
$146a:  21           DB  $21
$146b:  d0           DB  $d0
$146c:  4a           DB  $4a
$146d:  22           DB  $22
$146e:  88           DB  $88
$146f:  62           DB  $62
$1470:  21           DB  $21
$1471:  92           DB  $92
$1472:  3f           DB  $3f
$1473:  22           DB  $22
$1474:  8c           DB  $8c
$1475:  62           DB  $62
$1476:  cd           DB  $cd
$1477:  ca           DB  $ca
$1478:  42           DB  $42
$1479:  c9           DB  $c9
$147a:  cd           DB  $cd
$147b:  d8           DB  $d8
$147c:  19           DB  $19
$147d:  ca           DB  $ca
$147e:  b2           DB  $b2
$147f:  14           DB  $14
$1480:  cd           DB  $cd
$1481:  f4           DB  $f4
$1482:  25           DB  $25
$1483:  cd           DB  $cd
$1484:  ca           DB  $ca
$1485:  19           DB  $19
$1486:  c2           DB  $c2
$1487:  5a           DB  $5a
$1488:  0b           DB  $0b
$1489:  22           DB  $22
$148a:  84           DB  $84
$148b:  61           DB  $61
$148c:  eb           DB  $eb
$148d:  22           DB  $22
$148e:  86           DB  $86
$148f:  61           DB  $61
$1490:  cd           DB  $cd
$1491:  f1           DB  $f1
$1492:  25           DB  $25
$1493:  cd           DB  $cd
$1494:  db           DB  $db
$1495:  19           DB  $19
$1496:  c2           DB  $c2
$1497:  5a           DB  $5a
$1498:  0b           DB  $0b
$1499:  22           DB  $22
$149a:  8c           DB  $8c
$149b:  62           DB  $62
$149c:  eb           DB  $eb
$149d:  22           DB  $22
$149e:  8e           DB  $8e
$149f:  62           DB  $62
$14a0:  2a           DB  $2a
$14a1:  84           DB  $84
$14a2:  61           DB  $61
$14a3:  22           DB  $22
$14a4:  88           DB  $88
$14a5:  62           DB  $62
$14a6:  2a           DB  $2a
$14a7:  86           DB  $86
$14a8:  61           DB  $61
$14a9:  22           DB  $22
$14aa:  8a           DB  $8a
$14ab:  62           DB  $62
$14ac:  cd           DB  $cd
$14ad:  23           DB  $23
$14ae:  43           DB  $43
$14af:  c3           DB  $c3
$14b0:  5a           DB  $5a
$14b1:  0b           DB  $0b
$14b2:  cd           DB  $cd
$14b3:  b8           DB  $b8
$14b4:  14           DB  $14
$14b5:  c3           DB  $c3
$14b6:  5a           DB  $5a
$14b7:  0b           DB  $0b

F_L_14b8:
$14b8:  21 00 00            LXI      H,$0000
$14bb:  22 8a 62            SHLD     $628a
$14be:  22 8e 62            SHLD     $628e
$14c1:  21 ff 4f            LXI      H,$4fff
$14c4:  22 88 62            SHLD     $6288
$14c7:  21 00 80            LXI      H,$8000
$14ca:  22 8c 62            SHLD     $628c
$14cd:  cd 23 43            CALL     $4323
$14d0:  c9                  RET
$14d1:  21 05 00            LXI      H,$0005
$14d4:  22 c2 61            SHLD     $61c2
$14d7:  0e 00               MVI      C,$00
$14d9:  cd 87 25            CALL     $2587
$14dc:  cd ca 19            CALL     $19ca
$14df:  c2 5a 0b            JNZ      $0b5a
$14e2:  22 c6 61            SHLD     $61c6
$14e5:  0e 0f               MVI      C,$0f
$14e7:  cd 87 25            CALL     $2587
$14ea:  cd ca 19            CALL     $19ca
$14ed:  c2 5a 0b            JNZ      $0b5a
$14f0:  22 c8 61            SHLD     $61c8
$14f3:  cd 48 26            CALL     $2648
$14f6:  cd ca 19            CALL     $19ca
$14f9:  22 be 61            SHLD     $61be
$14fc:  c2 08 15            JNZ      $1508
$14ff:  cd 48 26            CALL     $2648
$1502:  cd ca 19            CALL     $19ca
$1505:  22 c2 61            SHLD     $61c2

F_L_1508:
$1508:  fe 3b               CPI      $3b
$150a:  c2 5a 0b            JNZ      $0b5a
$150d:  cd 7c 02            CALL     $027c
$1510:  cd 14 36            CALL     $3614
$1513:  cd 88 02            CALL     $0288
$1516:  c3 5a 0b            JMP      $0b5a
$1519:  21           DB  $21
$151a:  05           DB  $05
$151b:  00           DB  $00
$151c:  22           DB  $22
$151d:  c2           DB  $c2
$151e:  61           DB  $61
$151f:  0e           DB  $0e
$1520:  00           DB  $00
$1521:  cd           DB  $cd
$1522:  87           DB  $87
$1523:  25           DB  $25
$1524:  cd           DB  $cd
$1525:  ca           DB  $ca
$1526:  19           DB  $19
$1527:  c2           DB  $c2
$1528:  5a           DB  $5a
$1529:  0b           DB  $0b
$152a:  22           DB  $22
$152b:  80           DB  $80
$152c:  61           DB  $61
$152d:  0e           DB  $0e
$152e:  0f           DB  $0f
$152f:  cd           DB  $cd
$1530:  87           DB  $87
$1531:  25           DB  $25
$1532:  cd           DB  $cd
$1533:  ca           DB  $ca
$1534:  19           DB  $19
$1535:  c2           DB  $c2
$1536:  5a           DB  $5a
$1537:  0b           DB  $0b
$1538:  22           DB  $22
$1539:  82           DB  $82
$153a:  61           DB  $61
$153b:  cd           DB  $cd
$153c:  48           DB  $48
$153d:  26           DB  $26
$153e:  cd           DB  $cd
$153f:  ca           DB  $ca
$1540:  19           DB  $19
$1541:  22           DB  $22
$1542:  be           DB  $be
$1543:  61           DB  $61
$1544:  c2           DB  $c2
$1545:  50           DB  $50
$1546:  15           DB  $15
$1547:  cd           DB  $cd
$1548:  48           DB  $48
$1549:  26           DB  $26
$154a:  cd           DB  $cd
$154b:  ca           DB  $ca
$154c:  19           DB  $19
$154d:  22           DB  $22
$154e:  c2           DB  $c2
$154f:  61           DB  $61
$1550:  fe           DB  $fe
$1551:  3b           DB  $3b

F_L_1552:
$1552:  c2 5a 0b            JNZ      $0b5a
$1555:  cd 6b 15            CALL     $156b
$1558:  22 c6 61            SHLD     $61c6
$155b:  eb                  XCHG
$155c:  22 c8 61            SHLD     $61c8
$155f:  cd 7c 02            CALL     $027c
$1562:  cd 14 36            CALL     $3614
$1565:  cd 88 02            CALL     $0288
$1568:  c3 5a 0b            JMP      $0b5a

F_L_156b:
$156b:  2a 80 61            LHLD     $6180
$156e:  eb                  XCHG
$156f:  2a 4e 63            LHLD     $634e
$1572:  cd b4 28            CALL     $28b4
$1575:  e5                  PUSH     H
$1576:  2a 82 61            LHLD     $6182
$1579:  eb                  XCHG
$157a:  2a 50 63            LHLD     $6350
$157d:  cd b4 28            CALL     $28b4
$1580:  d1                  POP      D
$1581:  eb                  XCHG
$1582:  c9                  RET
$1583:  cd d8 19            CALL     $19d8
$1586:  ca bb 15            JZ       $15bb
$1589:  cd f4 25            CALL     $25f4
$158c:  cd ca 19            CALL     $19ca
$158f:  c2 5a 0b            JNZ      $0b5a
$1592:  22 84 61            SHLD     $6184
$1595:  eb                  XCHG
$1596:  22 86 61            SHLD     $6186
$1599:  cd f1 25            CALL     $25f1
$159c:  cd db 19            CALL     $19db
$159f:  c2 5a 0b            JNZ      $0b5a
$15a2:  22 8c 62            SHLD     $628c
$15a5:  eb                  XCHG
$15a6:  22 8e 62            SHLD     $628e
$15a9:  2a 84 61            LHLD     $6184
$15ac:  22 88 62            SHLD     $6288
$15af:  2a 86 61            LHLD     $6186
$15b2:  22 8a 62            SHLD     $628a
$15b5:  cd 17 44            CALL     $4417
$15b8:  c3 5a 0b            JMP      $0b5a

F_L_15bb:
$15bb:  cd c1 15            CALL     $15c1
$15be:  c3 5a 0b            JMP      $0b5a

F_L_15c1:
$15c1:  21 00 00            LXI      H,$0000
$15c4:  22 88 62            SHLD     $6288
$15c7:  22 8c 62            SHLD     $628c
$15ca:  22 8e 62            SHLD     $628e
$15cd:  23                  INX      H
$15ce:  22 8a 62            SHLD     $628a
$15d1:  cd 5f 43            CALL     $435f
$15d4:  c9                  RET
$15d5:  cd d8 19            CALL     $19d8
$15d8:  ca 0d 16            JZ       $160d
$15db:  cd f4 25            CALL     $25f4
$15de:  cd ca 19            CALL     $19ca
$15e1:  c2 5a 0b            JNZ      $0b5a
$15e4:  22 84 61            SHLD     $6184
$15e7:  eb                  XCHG
$15e8:  22 86 61            SHLD     $6186
$15eb:  cd f1 25            CALL     $25f1
$15ee:  cd db 19            CALL     $19db
$15f1:  c2 5a 0b            JNZ      $0b5a
$15f4:  22 8c 62            SHLD     $628c
$15f7:  eb                  XCHG
$15f8:  22 8e 62            SHLD     $628e
$15fb:  2a 84 61            LHLD     $6184
$15fe:  22 88 62            SHLD     $6288
$1601:  2a 86 61            LHLD     $6186
$1604:  22 8a 62            SHLD     $628a
$1607:  cd 17 44            CALL     $4417
$160a:  c3 5a 0b            JMP      $0b5a

F_L_160d:
$160d:  cd 13 16            CALL     $1613
$1610:  c3 5a 0b            JMP      $0b5a

F_L_1613:
$1613:  21 00 00            LXI      H,$0000
$1616:  22 88 62            SHLD     $6288
$1619:  22 8c 62            SHLD     $628c
$161c:  22 8e 62            SHLD     $628e
$161f:  23                  INX      H
$1620:  22 8a 62            SHLD     $628a
$1623:  cd 17 44            CALL     $4417
$1626:  c9                  RET
$1627:  cd 44 61            CALL     $6144
$162a:  fe 3b               CPI      $3b
$162c:  ca 43 16            JZ       $1643
$162f:  32 80 61            STA      $6180
$1632:  cd 44 61            CALL     $6144
$1635:  fe 3b               CPI      $3b
$1637:  c2 5a 0b            JNZ      $0b5a
$163a:  3a 80 61            LDA      $6180

F_L_163d:
$163d:  32 ed 62            STA      $62ed
$1640:  c3 5a 0b            JMP      $0b5a

F_L_1643:
$1643:  3e 03               MVI      A,$03
$1645:  c3 3d 16            JMP      $163d
$1648:  0e           DB  $0e
$1649:  00           DB  $00
$164a:  cd           DB  $cd
$164b:  87           DB  $87
$164c:  25           DB  $25
$164d:  22           DB  $22
$164e:  80           DB  $80
$164f:  61           DB  $61
$1650:  cd           DB  $cd
$1651:  ca           DB  $ca
$1652:  19           DB  $19
$1653:  c2           DB  $c2
$1654:  5a           DB  $5a
$1655:  0b           DB  $0b
$1656:  0e           DB  $0e
$1657:  0f           DB  $0f
$1658:  cd           DB  $cd
$1659:  87           DB  $87
$165a:  25           DB  $25
$165b:  cd           DB  $cd
$165c:  db           DB  $db
$165d:  19           DB  $19
$165e:  c2           DB  $c2
$165f:  5a           DB  $5a
$1660:  0b           DB  $0b
$1661:  22           DB  $22
$1662:  5f           DB  $5f
$1663:  63           DB  $63
$1664:  2a           DB  $2a
$1665:  80           DB  $80
$1666:  61           DB  $61
$1667:  22           DB  $22
$1668:  5d           DB  $5d
$1669:  63           DB  $63
$166a:  21           DB  $21
$166b:  00           DB  $00
$166c:  00           DB  $00
$166d:  22           DB  $22
$166e:  d6           DB  $d6
$166f:  61           DB  $61
$1670:  cd           DB  $cd
$1671:  7c           DB  $7c
$1672:  02           DB  $02
$1673:  cd           DB  $cd
$1674:  65           DB  $65
$1675:  2c           DB  $2c
$1676:  cd           DB  $cd
$1677:  88           DB  $88
$1678:  02           DB  $02
$1679:  c3           DB  $c3
$167a:  5a           DB  $5a
$167b:  0b           DB  $0b
$167c:  0e           DB  $0e
$167d:  00           DB  $00
$167e:  cd           DB  $cd
$167f:  87           DB  $87
$1680:  25           DB  $25
$1681:  22           DB  $22
$1682:  80           DB  $80
$1683:  61           DB  $61
$1684:  cd           DB  $cd
$1685:  ca           DB  $ca
$1686:  19           DB  $19
$1687:  c2           DB  $c2
$1688:  5a           DB  $5a
$1689:  0b           DB  $0b
$168a:  0e           DB  $0e
$168b:  0f           DB  $0f
$168c:  cd           DB  $cd
$168d:  87           DB  $87
$168e:  25           DB  $25
$168f:  cd           DB  $cd
$1690:  db           DB  $db
$1691:  19           DB  $19
$1692:  c2           DB  $c2
$1693:  5a           DB  $5a
$1694:  0b           DB  $0b
$1695:  22           DB  $22
$1696:  5f           DB  $5f
$1697:  63           DB  $63
$1698:  2a           DB  $2a
$1699:  80           DB  $80
$169a:  61           DB  $61
$169b:  22           DB  $22
$169c:  5d           DB  $5d
$169d:  63           DB  $63
$169e:  21           DB  $21
$169f:  01           DB  $01
$16a0:  00           DB  $00
$16a1:  c3           DB  $c3
$16a2:  6d           DB  $6d
$16a3:  16           DB  $16
$16a4:  0e           DB  $0e
$16a5:  00           DB  $00
$16a6:  cd           DB  $cd
$16a7:  87           DB  $87
$16a8:  25           DB  $25
$16a9:  22           DB  $22
$16aa:  80           DB  $80
$16ab:  61           DB  $61
$16ac:  cd           DB  $cd
$16ad:  ca           DB  $ca
$16ae:  19           DB  $19
$16af:  c2           DB  $c2
$16b0:  5a           DB  $5a
$16b1:  0b           DB  $0b
$16b2:  0e           DB  $0e
$16b3:  0f           DB  $0f
$16b4:  cd           DB  $cd
$16b5:  87           DB  $87
$16b6:  25           DB  $25
$16b7:  cd           DB  $cd
$16b8:  db           DB  $db
$16b9:  19           DB  $19
$16ba:  c2           DB  $c2
$16bb:  5a           DB  $5a
$16bc:  0b           DB  $0b
$16bd:  22           DB  $22
$16be:  82           DB  $82
$16bf:  61           DB  $61
$16c0:  cd           DB  $cd
$16c1:  6b           DB  $6b
$16c2:  15           DB  $15
$16c3:  22           DB  $22
$16c4:  5d           DB  $5d
$16c5:  63           DB  $63
$16c6:  eb           DB  $eb
$16c7:  22           DB  $22
$16c8:  5f           DB  $5f
$16c9:  63           DB  $63
$16ca:  21           DB  $21
$16cb:  00           DB  $00
$16cc:  00           DB  $00
$16cd:  c3           DB  $c3
$16ce:  6d           DB  $6d
$16cf:  16           DB  $16
$16d0:  0e           DB  $0e
$16d1:  00           DB  $00
$16d2:  cd           DB  $cd
$16d3:  87           DB  $87
$16d4:  25           DB  $25
$16d5:  22           DB  $22
$16d6:  80           DB  $80
$16d7:  61           DB  $61
$16d8:  cd           DB  $cd
$16d9:  ca           DB  $ca
$16da:  19           DB  $19
$16db:  c2           DB  $c2
$16dc:  5a           DB  $5a
$16dd:  0b           DB  $0b
$16de:  0e           DB  $0e
$16df:  0f           DB  $0f
$16e0:  cd           DB  $cd
$16e1:  87           DB  $87
$16e2:  25           DB  $25
$16e3:  cd           DB  $cd
$16e4:  db           DB  $db
$16e5:  19           DB  $19
$16e6:  c2           DB  $c2
$16e7:  5a           DB  $5a
$16e8:  0b           DB  $0b
$16e9:  22           DB  $22
$16ea:  82           DB  $82
$16eb:  61           DB  $61
$16ec:  cd           DB  $cd
$16ed:  6b           DB  $6b
$16ee:  15           DB  $15
$16ef:  22           DB  $22
$16f0:  5d           DB  $5d
$16f1:  63           DB  $63
$16f2:  eb           DB  $eb
$16f3:  22           DB  $22
$16f4:  5f           DB  $5f
$16f5:  63           DB  $63
$16f6:  21           DB  $21
$16f7:  01           DB  $01
$16f8:  00           DB  $00
$16f9:  c3           DB  $c3
$16fa:  6d           DB  $6d
$16fb:  16           DB  $16
$16fc:  0e           DB  $0e
$16fd:  00           DB  $00
$16fe:  cd           DB  $cd
$16ff:  87           DB  $87
$1700:  25           DB  $25
$1701:  22           DB  $22
$1702:  80           DB  $80
$1703:  61           DB  $61
$1704:  cd           DB  $cd
$1705:  ca           DB  $ca
$1706:  19           DB  $19
$1707:  c2           DB  $c2
$1708:  5a           DB  $5a
$1709:  0b           DB  $0b
$170a:  0e           DB  $0e
$170b:  0f           DB  $0f
$170c:  cd           DB  $cd
$170d:  87           DB  $87
$170e:  25           DB  $25
$170f:  cd           DB  $cd
$1710:  db           DB  $db
$1711:  19           DB  $19
$1712:  c2           DB  $c2
$1713:  5a           DB  $5a
$1714:  0b           DB  $0b
$1715:  22           DB  $22
$1716:  5f           DB  $5f
$1717:  63           DB  $63
$1718:  2a           DB  $2a
$1719:  80           DB  $80
$171a:  61           DB  $61
$171b:  22           DB  $22
$171c:  5d           DB  $5d
$171d:  63           DB  $63
$171e:  c3           DB  $c3
$171f:  70           DB  $70
$1720:  16           DB  $16
$1721:  cd           DB  $cd
$1722:  d8           DB  $d8
$1723:  19           DB  $19
$1724:  ca           DB  $ca
$1725:  1b           DB  $1b
$1726:  18           DB  $18
$1727:  cd           DB  $cd
$1728:  4b           DB  $4b
$1729:  26           DB  $26
$172a:  7c           DB  $7c
$172b:  a7           DB  $a7
$172c:  c2           DB  $c2
$172d:  5a           DB  $5a
$172e:  0b           DB  $0b
$172f:  7d           DB  $7d
$1730:  fe           DB  $fe
$1731:  06           DB  $06
$1732:  d2           DB  $d2
$1733:  5a           DB  $5a
$1734:  0b           DB  $0b
$1735:  a7           DB  $a7
$1736:  ca           DB  $ca
$1737:  5a           DB  $5a
$1738:  0b           DB  $0b
$1739:  fe           DB  $fe
$173a:  03           DB  $03
$173b:  da           DB  $da
$173c:  c3           DB  $c3
$173d:  17           DB  $17
$173e:  cd           DB  $cd
$173f:  ca           DB  $ca
$1740:  19           DB  $19
$1741:  22           DB  $22
$1742:  80           DB  $80
$1743:  61           DB  $61
$1744:  c2           DB  $c2
$1745:  5a           DB  $5a
$1746:  0b           DB  $0b
$1747:  cd           DB  $cd
$1748:  48           DB  $48
$1749:  26           DB  $26
$174a:  22           DB  $22
$174b:  82           DB  $82
$174c:  61           DB  $61
$174d:  cd           DB  $cd
$174e:  ca           DB  $ca
$174f:  19           DB  $19
$1750:  ca           DB  $ca
$1751:  61           DB  $61
$1752:  17           DB  $17
$1753:  fe           DB  $fe
$1754:  3b           DB  $3b
$1755:  c2           DB  $c2
$1756:  5a           DB  $5a
$1757:  0b           DB  $0b
$1758:  2a           DB  $2a
$1759:  82           DB  $82
$175a:  61           DB  $61
$175b:  22           DB  $22
$175c:  d4           DB  $d4
$175d:  61           DB  $61
$175e:  c3           DB  $c3
$175f:  5a           DB  $5a
$1760:  0b           DB  $0b
$1761:  cd           DB  $cd
$1762:  48           DB  $48
$1763:  26           DB  $26
$1764:  cd           DB  $cd
$1765:  db           DB  $db
$1766:  19           DB  $19
$1767:  c2           DB  $c2
$1768:  5a           DB  $5a
$1769:  0b           DB  $0b
$176a:  11           DB  $11
$176b:  17           DB  $17
$176c:  00           DB  $00
$176d:  06           DB  $06
$176e:  04           DB  $04
$176f:  cd           DB  $cd
$1770:  ea           DB  $ea
$1771:  27           DB  $27
$1772:  da           DB  $da
$1773:  98           DB  $98
$1774:  17           DB  $17
$1775:  11           DB  $11
$1776:  44           DB  $44
$1777:  00           DB  $00
$1778:  06           DB  $06
$1779:  02           DB  $02
$177a:  cd           DB  $cd
$177b:  ea           DB  $ea
$177c:  27           DB  $27
$177d:  da           DB  $da
$177e:  98           DB  $98
$177f:  17           DB  $17
$1780:  11           DB  $11
$1781:  71           DB  $71
$1782:  00           DB  $00
$1783:  06           DB  $06
$1784:  01           DB  $01
$1785:  cd           DB  $cd
$1786:  ea           DB  $ea
$1787:  27           DB  $27
$1788:  da           DB  $da
$1789:  98           DB  $98
$178a:  17           DB  $17
$178b:  11           DB  $11
$178c:  9e           DB  $9e
$178d:  00           DB  $00
$178e:  06           DB  $06
$178f:  08           DB  $08
$1790:  cd           DB  $cd
$1791:  ea           DB  $ea
$1792:  27           DB  $27
$1793:  d2           DB  $d2
$1794:  98           DB  $98
$1795:  17           DB  $17
$1796:  06           DB  $06
$1797:  04           DB  $04
$1798:  26           DB  $26
$1799:  00           DB  $00
$179a:  68           DB  $68
$179b:  3a           DB  $3a
$179c:  80           DB  $80
$179d:  61           DB  $61
$179e:  fe           DB  $fe
$179f:  05           DB  $05
$17a0:  ca           DB  $ca
$17a1:  ba           DB  $ba
$17a2:  17           DB  $17
$17a3:  fe           DB  $fe
$17a4:  04           DB  $04
$17a5:  c2           DB  $c2
$17a6:  b4           DB  $b4
$17a7:  17           DB  $17
$17a8:  78           DB  $78
$17a9:  e6           DB  $e6
$17aa:  05           DB  $05
$17ab:  21           DB  $21
$17ac:  0a           DB  $0a
$17ad:  00           DB  $00
$17ae:  ca           DB  $ca
$17af:  b4           DB  $b4
$17b0:  17           DB  $17
$17b1:  21           DB  $21
$17b2:  05           DB  $05
$17b3:  00           DB  $00
$17b4:  22           DB  $22
$17b5:  ce           DB  $ce
$17b6:  61           DB  $61
$17b7:  c3           DB  $c3
$17b8:  58           DB  $58
$17b9:  17           DB  $17
$17ba:  21           DB  $21
$17bb:  00           DB  $00
$17bc:  00           DB  $00
$17bd:  22           DB  $22
$17be:  ce           DB  $ce
$17bf:  61           DB  $61
$17c0:  c3           DB  $c3
$17c1:  5a           DB  $5a
$17c2:  0b           DB  $0b
$17c3:  cd           DB  $cd
$17c4:  db           DB  $db
$17c5:  19           DB  $19
$17c6:  c2           DB  $c2
$17c7:  5a           DB  $5a
$17c8:  0b           DB  $0b
$17c9:  2a           DB  $2a
$17ca:  36           DB  $36
$17cb:  62           DB  $62
$17cc:  22           DB  $22
$17cd:  d4           DB  $d4
$17ce:  61           DB  $61
$17cf:  21           DB  $21
$17d0:  04           DB  $04
$17d1:  00           DB  $00
$17d2:  22           DB  $22
$17d3:  ce           DB  $ce
$17d4:  61           DB  $61
$17d5:  c3           DB  $c3
$17d6:  5a           DB  $5a
$17d7:  0b           DB  $0b
$17d8:  cd           DB  $cd
$17d9:  d8           DB  $d8
$17da:  19           DB  $19
$17db:  ca           DB  $ca
$17dc:  1b           DB  $1b
$17dd:  18           DB  $18
$17de:  cd           DB  $cd
$17df:  4b           DB  $4b
$17e0:  26           DB  $26
$17e1:  cd           DB  $cd
$17e2:  ca           DB  $ca
$17e3:  19           DB  $19
$17e4:  22           DB  $22
$17e5:  80           DB  $80
$17e6:  61           DB  $61
$17e7:  ca           DB  $ca
$17e8:  ef           DB  $ef
$17e9:  17           DB  $17
$17ea:  fe           DB  $fe
$17eb:  3b           DB  $3b
$17ec:  ca           DB  $ca
$17ed:  12           DB  $12
$17ee:  18           DB  $18
$17ef:  cd           DB  $cd
$17f0:  48           DB  $48
$17f1:  26           DB  $26
$17f2:  cd           DB  $cd
$17f3:  ca           DB  $ca
$17f4:  19           DB  $19
$17f5:  22           DB  $22
$17f6:  82           DB  $82
$17f7:  61           DB  $61
$17f8:  ca           DB  $ca
$17f9:  00           DB  $00
$17fa:  18           DB  $18
$17fb:  fe           DB  $fe
$17fc:  3b           DB  $3b
$17fd:  ca           DB  $ca
$17fe:  47           DB  $47
$17ff:  17           DB  $17
$1800:  cd           DB  $cd
$1801:  48           DB  $48
$1802:  26           DB  $26
$1803:  cd           DB  $cd
$1804:  db           DB  $db
$1805:  19           DB  $19
$1806:  c2           DB  $c2
$1807:  5a           DB  $5a
$1808:  0b           DB  $0b
$1809:  22           DB  $22
$180a:  ce           DB  $ce
$180b:  61           DB  $61
$180c:  2a           DB  $2a
$180d:  82           DB  $82
$180e:  61           DB  $61
$180f:  22           DB  $22
$1810:  d4           DB  $d4
$1811:  61           DB  $61
$1812:  2a           DB  $2a
$1813:  80           DB  $80
$1814:  61           DB  $61
$1815:  22           DB  $22
$1816:  d6           DB  $d6
$1817:  61           DB  $61
$1818:  c3           DB  $c3
$1819:  5a           DB  $5a
$181a:  0b           DB  $0b
$181b:  cd           DB  $cd
$181c:  21           DB  $21
$181d:  18           DB  $18
$181e:  c3           DB  $c3
$181f:  5a           DB  $5a
$1820:  0b           DB  $0b

F_L_1821:
$1821:  21 01 00            LXI      H,$0001
$1824:  22 d6 61            SHLD     $61d6
$1827:  21 04 00            LXI      H,$0004
$182a:  22 ce 61            SHLD     $61ce
$182d:  3a f0 63            LDA      $63f0
$1830:  e6 01               ANI      $01
$1832:  21 48 00            LXI      H,$0048
$1835:  c2 3b 18            JNZ      $183b
$1838:  21 66 00            LXI      H,$0066

F_L_183b:
$183b:  22 d4 61            SHLD     $61d4
$183e:  c9                  RET
$183f:  3a ec 62            LDA      $62ec
$1842:  e6 03               ANI      $03
$1844:  32 ec 62            STA      $62ec
$1847:  cd 7c 02            CALL     $027c
$184a:  cd 44 61            CALL     $6144
$184d:  cd 65 02            CALL     $0265
$1850:  cd 0c 11            CALL     $110c
$1853:  cd c0 3a            CALL     $3ac0
$1856:  cd 73 02            CALL     $0273
$1859:  cd 88 02            CALL     $0288
$185c:  c3 5a 0b            JMP      $0b5a
$185f:  cd           DB  $cd
$1860:  d8           DB  $d8
$1861:  19           DB  $19
$1862:  ca           DB  $ca
$1863:  99           DB  $99
$1864:  18           DB  $18
$1865:  cd           DB  $cd
$1866:  4b           DB  $4b
$1867:  26           DB  $26
$1868:  7c           DB  $7c
$1869:  a7           DB  $a7
$186a:  c2           DB  $c2
$186b:  5a           DB  $5a
$186c:  0b           DB  $0b
$186d:  7d           DB  $7d
$186e:  a7           DB  $a7
$186f:  fa           DB  $fa
$1870:  5a           DB  $5a
$1871:  0b           DB  $0b
$1872:  ca           DB  $ca
$1873:  5a           DB  $5a
$1874:  0b           DB  $0b
$1875:  fe           DB  $fe
$1876:  14           DB  $14
$1877:  d2           DB  $d2
$1878:  5a           DB  $5a
$1879:  0b           DB  $0b
$187a:  32           DB  $32
$187b:  31           DB  $31
$187c:  63           DB  $63
$187d:  3a           DB  $3a
$187e:  ec           DB  $ec
$187f:  62           DB  $62
$1880:  e6           DB  $e6
$1881:  03           DB  $03
$1882:  f6           DB  $f6
$1883:  10           DB  $10
$1884:  32           DB  $32
$1885:  ec           DB  $ec
$1886:  62           DB  $62
$1887:  cd           DB  $cd
$1888:  7c           DB  $7c
$1889:  02           DB  $02
$188a:  cd           DB  $cd
$188b:  65           DB  $65
$188c:  02           DB  $02
$188d:  cd           DB  $cd
$188e:  c0           DB  $c0
$188f:  3a           DB  $3a
$1890:  cd           DB  $cd
$1891:  73           DB  $73
$1892:  02           DB  $02
$1893:  cd           DB  $cd
$1894:  88           DB  $88
$1895:  02           DB  $02
$1896:  c3           DB  $c3
$1897:  5a           DB  $5a
$1898:  0b           DB  $0b
$1899:  3e           DB  $3e
$189a:  01           DB  $01
$189b:  c3           DB  $c3
$189c:  7a           DB  $7a
$189d:  18           DB  $18
$189e:  cd           DB  $cd
$189f:  d8           DB  $d8
$18a0:  19           DB  $19
$18a1:  c2           DB  $c2
$18a2:  b2           DB  $b2
$18a3:  18           DB  $18
$18a4:  cd           DB  $cd
$18a5:  7c           DB  $7c
$18a6:  02           DB  $02
$18a7:  3a           DB  $3a
$18a8:  f0           DB  $f0
$18a9:  63           DB  $63
$18aa:  e6           DB  $e6
$18ab:  01           DB  $01
$18ac:  c4           DB  $c4
$18ad:  7c           DB  $7c
$18ae:  06           DB  $06
$18af:  c3           DB  $c3
$18b0:  e2           DB  $e2
$18b1:  18           DB  $18
$18b2:  32           DB  $32
$18b3:  80           DB  $80
$18b4:  61           DB  $61
$18b5:  cd           DB  $cd
$18b6:  db           DB  $db
$18b7:  19           DB  $19
$18b8:  c2           DB  $c2
$18b9:  5a           DB  $5a
$18ba:  0b           DB  $0b
$18bb:  3a           DB  $3a
$18bc:  80           DB  $80
$18bd:  61           DB  $61
$18be:  fe           DB  $fe
$18bf:  30           DB  $30
$18c0:  ca           DB  $ca
$18c1:  a4           DB  $a4
$18c2:  18           DB  $18
$18c3:  fe           DB  $fe
$18c4:  31           DB  $31
$18c5:  ca           DB  $ca
$18c6:  a4           DB  $a4
$18c7:  18           DB  $18
$18c8:  fe           DB  $fe
$18c9:  33           DB  $33
$18ca:  ca           DB  $ca
$18cb:  a4           DB  $a4
$18cc:  18           DB  $18
$18cd:  fe           DB  $fe
$18ce:  32           DB  $32
$18cf:  ca           DB  $ca
$18d0:  a4           DB  $a4
$18d1:  18           DB  $18
$18d2:  fe           DB  $fe
$18d3:  34           DB  $34
$18d4:  c2           DB  $c2
$18d5:  e8           DB  $e8
$18d6:  18           DB  $18
$18d7:  cd           DB  $cd
$18d8:  7c           DB  $7c
$18d9:  02           DB  $02
$18da:  3a           DB  $3a
$18db:  f0           DB  $f0
$18dc:  63           DB  $63
$18dd:  e6           DB  $e6
$18de:  01           DB  $01
$18df:  ca           DB  $ca
$18e0:  cb           DB  $cb
$18e1:  05           DB  $05
$18e2:  cd           DB  $cd
$18e3:  88           DB  $88
$18e4:  02           DB  $02
$18e5:  c3           DB  $c3
$18e6:  5a           DB  $5a
$18e7:  0b           DB  $0b
$18e8:  3e           DB  $3e
$18e9:  03           DB  $03
$18ea:  32           DB  $32
$18eb:  de           DB  $de
$18ec:  63           DB  $63
$18ed:  c3           DB  $c3
$18ee:  5a           DB  $5a
$18ef:  0b           DB  $0b
$18f0:  cd           DB  $cd
$18f1:  d8           DB  $d8
$18f2:  19           DB  $19
$18f3:  ca           DB  $ca
$18f4:  11           DB  $11
$18f5:  19           DB  $19
$18f6:  cd           DB  $cd
$18f7:  f4           DB  $f4
$18f8:  25           DB  $25
$18f9:  cd           DB  $cd
$18fa:  db           DB  $db
$18fb:  19           DB  $19
$18fc:  c2           DB  $c2
$18fd:  5a           DB  $5a
$18fe:  0b           DB  $0b
$18ff:  22           DB  $22
$1900:  35           DB  $35
$1901:  63           DB  $63
$1902:  eb           DB  $eb
$1903:  22           DB  $22
$1904:  37           DB  $37
$1905:  63           DB  $63
$1906:  3a           DB  $3a
$1907:  ec           DB  $ec
$1908:  62           DB  $62
$1909:  f6           DB  $f6
$190a:  01           DB  $01
$190b:  32           DB  $32
$190c:  ec           DB  $ec
$190d:  62           DB  $62
$190e:  c3           DB  $c3
$190f:  5a           DB  $5a
$1910:  0b           DB  $0b
$1911:  cd           DB  $cd
$1912:  17           DB  $17
$1913:  19           DB  $19
$1914:  c3           DB  $c3
$1915:  5a           DB  $5a
$1916:  0b           DB  $0b

F_L_1917:
$1917:  21 00 00            LXI      H,$0000
$191a:  22 35 63            SHLD     $6335
$191d:  22 37 63            SHLD     $6337
$1920:  3a ec 62            LDA      $62ec
$1923:  f6 01               ORI      $01
$1925:  32 ec 62            STA      $62ec
$1928:  c9                  RET
$1929:  cd d8 19            CALL     $19d8
$192c:  ca 41 19            JZ       $1941
$192f:  32 80 61            STA      $6180
$1932:  cd d8 19            CALL     $19d8
$1935:  c2 5a 0b            JNZ      $0b5a
$1938:  3a 80 61            LDA      $6180

F_L_193b:
$193b:  32 33 63            STA      $6333
$193e:  c3 5a 0b            JMP      $0b5a

F_L_1941:
$1941:  af                  XRA      A
$1942:  c3 3b 19            JMP      $193b
$1945:  01           DB  $01
$1946:  ee           DB  $ee
$1947:  62           DB  $62
$1948:  16           DB  $16
$1949:  40           DB  $40
$194a:  c5           DB  $c5
$194b:  d5           DB  $d5
$194c:  cd           DB  $cd
$194d:  48           DB  $48
$194e:  26           DB  $26
$194f:  d1           DB  $d1
$1950:  c1           DB  $c1
$1951:  cd           DB  $cd
$1952:  ca           DB  $ca
$1953:  19           DB  $19
$1954:  ca           DB  $ca
$1955:  7b           DB  $7b
$1956:  19           DB  $19
$1957:  16           DB  $16
$1958:  01           DB  $01
$1959:  c3           DB  $c3
$195a:  7b           DB  $7b
$195b:  19           DB  $19
$195c:  3e           DB  $3e
$195d:  c1           DB  $c1
$195e:  02           DB  $02
$195f:  3a           DB  $3a
$1960:  ec           DB  $ec
$1961:  62           DB  $62
$1962:  e6           DB  $e6
$1963:  03           DB  $03
$1964:  f6           DB  $f6
$1965:  04           DB  $04
$1966:  32           DB  $32
$1967:  ec           DB  $ec
$1968:  62           DB  $62
$1969:  cd           DB  $cd
$196a:  7c           DB  $7c
$196b:  02           DB  $02
$196c:  cd           DB  $cd
$196d:  65           DB  $65
$196e:  02           DB  $02
$196f:  cd           DB  $cd
$1970:  c0           DB  $c0
$1971:  3a           DB  $3a
$1972:  cd           DB  $cd
$1973:  73           DB  $73
$1974:  02           DB  $02
$1975:  cd           DB  $cd
$1976:  88           DB  $88
$1977:  02           DB  $02
$1978:  c3           DB  $c3
$1979:  5a           DB  $5a
$197a:  0b           DB  $0b
$197b:  7c           DB  $7c
$197c:  e6           DB  $e6
$197d:  7f           DB  $7f
$197e:  c2           DB  $c2
$197f:  5c           DB  $5c
$1980:  19           DB  $19
$1981:  7d           DB  $7d
$1982:  e6           DB  $e6
$1983:  80           DB  $80
$1984:  c2           DB  $c2
$1985:  5c           DB  $5c
$1986:  19           DB  $19
$1987:  7c           DB  $7c
$1988:  e6           DB  $e6
$1989:  80           DB  $80
$198a:  c2           DB  $c2
$198b:  97           DB  $97
$198c:  19           DB  $19
$198d:  7d           DB  $7d
$198e:  02           DB  $02
$198f:  03           DB  $03
$1990:  15           DB  $15
$1991:  ca           DB  $ca
$1992:  5c           DB  $5c
$1993:  19           DB  $19
$1994:  c3           DB  $c3
$1995:  4a           DB  $4a
$1996:  19           DB  $19
$1997:  cd           DB  $cd
$1998:  db           DB  $db
$1999:  28           DB  $28
$199a:  c3           DB  $c3
$199b:  8d           DB  $8d
$199c:  19           DB  $19
$199d:  cd           DB  $cd
$199e:  d8           DB  $d8
$199f:  19           DB  $19
$19a0:  c2           DB  $c2
$19a1:  5a           DB  $5a
$19a2:  0b           DB  $0b
$19a3:  cd           DB  $cd
$19a4:  7c           DB  $7c
$19a5:  02           DB  $02
$19a6:  cd           DB  $cd
$19a7:  28           DB  $28
$19a8:  42           DB  $42
$19a9:  cd           DB  $cd
$19aa:  88           DB  $88
$19ab:  02           DB  $02
$19ac:  cd           DB  $cd
$19ad:  16           DB  $16
$19ae:  11           DB  $11
$19af:  c3           DB  $c3
$19b0:  5a           DB  $5a
$19b1:  0b           DB  $0b
$19b2:  cd           DB  $cd
$19b3:  d8           DB  $d8
$19b4:  19           DB  $19
$19b5:  c2           DB  $c2
$19b6:  5a           DB  $5a
$19b7:  0b           DB  $0b
$19b8:  cd           DB  $cd
$19b9:  7c           DB  $7c
$19ba:  02           DB  $02
$19bb:  cd           DB  $cd
$19bc:  79           DB  $79
$19bd:  42           DB  $42
$19be:  cd           DB  $cd
$19bf:  88           DB  $88
$19c0:  02           DB  $02
$19c1:  cd           DB  $cd
$19c2:  16           DB  $16
$19c3:  11           DB  $11
$19c4:  c3           DB  $c3
$19c5:  5a           DB  $5a
$19c6:  0b           DB  $0b

F_L_19c7:
$19c7:  cd 44 61            CALL     $6144

F_L_19ca:
$19ca:  3a 48 61            LDA      $6148
$19cd:  fe 20               CPI      $20
$19cf:  c2 d5 19            JNZ      $19d5
$19d2:  c3 c7 19            JMP      $19c7

F_L_19d5:
$19d5:  fe 2c               CPI      $2c
$19d7:  c9                  RET

F_L_19d8:
$19d8:  cd 44 61            CALL     $6144

F_L_19db:
$19db:  3a 48 61            LDA      $6148
$19de:  fe 20               CPI      $20
$19e0:  c2 e6 19            JNZ      $19e6
$19e3:  c3 d8 19            JMP      $19d8

F_L_19e6:
$19e6:  fe 3b               CPI      $3b
$19e8:  c9                  RET
$19e9:  f5                  PUSH     PSW
$19ea:  c5                  PUSH     B
$19eb:  e5                  PUSH     H
$19ec:  d5                  PUSH     D
$19ed:  3a 00 ec            LDA      $ec00
$19f0:  2a f8 63            LHLD     $63f8
$19f3:  f5                  PUSH     PSW
$19f4:  77                  MOV      M,A
$19f5:  01 e4 67            LXI      B,$67e4
$19f8:  7c                  MOV      A,H
$19f9:  b8                  CMP      B
$19fa:  c2 ff 19            JNZ      $19ff
$19fd:  7d                  MOV      A,L
$19fe:  b9                  CMP      C

F_L_19ff:
$19ff:  23                  INX      H
$1a00:  c2 06 1a            JNZ      $1a06
$1a03:  21 fd 63            LXI      H,$63fd

F_L_1a06:
$1a06:  22 f8 63            SHLD     $63f8
$1a09:  2a fa 63            LHLD     $63fa
$1a0c:  23                  INX      H
$1a0d:  22 fa 63            SHLD     $63fa
$1a10:  3a f2 63            LDA      $63f2
$1a13:  f6 02               ORI      $02
$1a15:  32 f2 63            STA      $63f2
$1a18:  01 bf 03            LXI      B,$03bf
$1a1b:  7c                  MOV      A,H
$1a1c:  b8                  CMP      B
$1a1d:  c2 22 1a            JNZ      $1a22
$1a20:  7d                  MOV      A,L
$1a21:  b9                  CMP      C

F_L_1a22:
$1a22:  da 42 1a            JC       $1a42
$1a25:  3a f2 63            LDA      $63f2
$1a28:  47                  MOV      B,A
$1a29:  e6 01               ANI      $01
$1a2b:  c2 42 1a            JNZ      $1a42
$1a2e:  78                  MOV      A,B
$1a2f:  f6 05               ORI      $05
$1a31:  32 f2 63            STA      $63f2

F_L_1a34:
$1a34:  3a 01 ec            LDA      $ec01
$1a37:  2f                  CMA
$1a38:  e6 05               ANI      $05
$1a3a:  c2 34 1a            JNZ      $1a34
$1a3d:  3e 13               MVI      A,$13
$1a3f:  32 00 ec            STA      $ec00

F_L_1a42:
$1a42:  f1                  POP      PSW
$1a43:  4f                  MOV      C,A
$1a44:  3a f3 63            LDA      $63f3
$1a47:  47                  MOV      B,A
$1a48:  1f                  RAR
$1a49:  d2 5f 1a            JNC      $1a5f
$1a4c:  3a ed 62            LDA      $62ed
$1a4f:  b9                  CMP      C
$1a50:  c2 59 1a            JNZ      $1a59
$1a53:  78                  MOV      A,B
$1a54:  e6 fe               ANI      $fe
$1a56:  32 f3 63            STA      $63f3

F_L_1a59:
$1a59:  d1                  POP      D
$1a5a:  e1                  POP      H
$1a5b:  c1                  POP      B
$1a5c:  f1                  POP      PSW
$1a5d:  fb                  EI
$1a5e:  c9                  RET

F_L_1a5f:
$1a5f:  1f                  RAR
$1a60:  da 9c 1a            JC       $1a9c

F_L_1a63:
$1a63:  79                  MOV      A,C
$1a64:  fe 4f               CPI      $4f
$1a66:  c2 6f 1a            JNZ      $1a6f

F_L_1a69:
$1a69:  78                  MOV      A,B
$1a6a:  f6 02               ORI      $02
$1a6c:  c3 7d 1a            JMP      $1a7d

F_L_1a6f:
$1a6f:  78                  MOV      A,B
$1a70:  17                  RAL
$1a71:  79                  MOV      A,C
$1a72:  da 83 1a            JC       $1a83
$1a75:  fe 4c               CPI      $4c
$1a77:  c2 59 1a            JNZ      $1a59
$1a7a:  78                  MOV      A,B
$1a7b:  f6 80               ORI      $80

F_L_1a7d:
$1a7d:  32 f3 63            STA      $63f3
$1a80:  c3 59 1a            JMP      $1a59

F_L_1a83:
$1a83:  fe 42               CPI      $42
$1a85:  ca 94 1a            JZ       $1a94
$1a88:  79                  MOV      A,C
$1a89:  fe 4f               CPI      $4f
$1a8b:  c2 69 1a            JNZ      $1a69
$1a8e:  78                  MOV      A,B
$1a8f:  e6 7f               ANI      $7f
$1a91:  c3 7d 1a            JMP      $1a7d

F_L_1a94:
$1a94:  78                  MOV      A,B
$1a95:  e6 7f               ANI      $7f
$1a97:  f6 01               ORI      $01
$1a99:  c3 7d 1a            JMP      $1a7d

F_L_1a9c:
$1a9c:  1f                  RAR
$1a9d:  da c3 1a            JC       $1ac3
$1aa0:  21 e4 1a            LXI      H,$1ae4
$1aa3:  79                  MOV      A,C
$1aa4:  0e 0a               MVI      C,$0a

F_L_1aa6:
$1aa6:  be                  CMP      M
$1aa7:  ca b8 1a            JZ       $1ab8
$1aaa:  23                  INX      H
$1aab:  0d                  DCR      C
$1aac:  c2 a6 1a            JNZ      $1aa6

F_L_1aaf:
$1aaf:  78                  MOV      A,B
$1ab0:  e6 f1               ANI      $f1

F_L_1ab2:
$1ab2:  32 f3 63            STA      $63f3
$1ab5:  c3 63 1a            JMP      $1a63

F_L_1ab8:
$1ab8:  21 f4 63            LXI      H,$63f4
$1abb:  71                  MOV      M,C
$1abc:  35                  DCR      M
$1abd:  78                  MOV      A,B
$1abe:  f6 04               ORI      $04
$1ac0:  c3 b2 1a            JMP      $1ab2

F_L_1ac3:
$1ac3:  79                  MOV      A,C
$1ac4:  fe 20               CPI      $20
$1ac6:  ca 59 1a            JZ       $1a59
$1ac9:  fe 3b               CPI      $3b
$1acb:  c2 af 1a            JNZ      $1aaf
$1ace:  3a f3 63            LDA      $63f3
$1ad1:  e6 f1               ANI      $f1
$1ad3:  32 f3 63            STA      $63f3
$1ad6:  21 f4 63            LXI      H,$63f4
$1ad9:  7e                  MOV      A,M
$1ada:  87                  ADD      A
$1adb:  86                  ADD      M
$1adc:  4f                  MOV      C,A
$1add:  06 00               MVI      B,$00
$1adf:  21 ee 1a            LXI      H,$1aee
$1ae2:  09                  DAD      B
$1ae3:  e9                  PCHL
$1ae4:  41                  MOV      B,C
$1ae5:  43                  MOV      B,E
$1ae6:  45                  MOV      B,L
$1ae7:  46                  MOV      B,M
$1ae8:  48                  MOV      C,B
$1ae9:  49                  NOP
$1aea:  4f                  MOV      C,A
$1aeb:  50                  MOV      D,B
$1aec:  53                  MOV      D,E
$1aed:  57                  MOV      D,A
$1aee:  c3 79 1b            JMP      $1b79
$1af1:  c3           DB  $c3
$1af2:  94           DB  $94
$1af3:  1b           DB  $1b
$1af4:  c3           DB  $c3
$1af5:  9e           DB  $9e
$1af6:  1b           DB  $1b
$1af7:  c3           DB  $c3
$1af8:  58           DB  $58
$1af9:  1b           DB  $1b
$1afa:  c3           DB  $c3
$1afb:  43           DB  $43
$1afc:  1b           DB  $1b
$1afd:  c3           DB  $c3
$1afe:  b6           DB  $b6
$1aff:  1b           DB  $1b
$1b00:  c3           DB  $c3
$1b01:  34           DB  $34
$1b02:  1b           DB  $1b
$1b03:  c3           DB  $c3
$1b04:  2b           DB  $2b
$1b05:  1b           DB  $1b
$1b06:  c3           DB  $c3
$1b07:  b9           DB  $b9
$1b08:  1b           DB  $1b
$1b09:  2a           DB  $2a
$1b0a:  c1           DB  $c1
$1b0b:  63           DB  $63
$1b0c:  cd           DB  $cd
$1b0d:  4c           DB  $4c
$1b0e:  27           DB  $27
$1b0f:  2a           DB  $2a
$1b10:  c3           DB  $c3
$1b11:  63           DB  $63
$1b12:  cd           DB  $cd
$1b13:  4c           DB  $4c
$1b14:  27           DB  $27
$1b15:  3a           DB  $3a
$1b16:  2f           DB  $2f
$1b17:  63           DB  $63
$1b18:  a7           DB  $a7
$1b19:  0e           DB  $0e
$1b1a:  31           DB  $31
$1b1b:  c2           DB  $c2
$1b1c:  20           DB  $20
$1b1d:  1b           DB  $1b
$1b1e:  0e           DB  $0e
$1b1f:  30           DB  $30
$1b20:  cd           DB  $cd
$1b21:  ff           DB  $ff
$1b22:  0a           DB  $0a
$1b23:  0e           DB  $0e
$1b24:  3b           DB  $3b
$1b25:  cd           DB  $cd
$1b26:  ff           DB  $ff
$1b27:  0a           DB  $0a
$1b28:  c3           DB  $c3
$1b29:  59           DB  $59
$1b2a:  1a           DB  $1a
$1b2b:  2a           DB  $2a
$1b2c:  de           DB  $de
$1b2d:  63           DB  $63
$1b2e:  cd           DB  $cd
$1b2f:  55           DB  $55
$1b30:  27           DB  $27
$1b31:  c3           DB  $c3
$1b32:  59           DB  $59
$1b33:  1a           DB  $1a
$1b34:  21           DB  $21
$1b35:  28           DB  $28
$1b36:  00           DB  $00
$1b37:  cd           DB  $cd
$1b38:  4c           DB  $4c
$1b39:  27           DB  $27
$1b3a:  21           DB  $21
$1b3b:  28           DB  $28
$1b3c:  00           DB  $00
$1b3d:  cd           DB  $cd
$1b3e:  55           DB  $55
$1b3f:  27           DB  $27
$1b40:  c3           DB  $c3
$1b41:  59           DB  $59
$1b42:  1a           DB  $1a
$1b43:  0e           DB  $0e
$1b44:  41           DB  $41
$1b45:  cd           DB  $cd
$1b46:  ff           DB  $ff
$1b47:  0a           DB  $0a
$1b48:  0e           DB  $0e
$1b49:  38           DB  $38
$1b4a:  cd           DB  $cd
$1b4b:  ff           DB  $ff
$1b4c:  0a           DB  $0a
$1b4d:  cd           DB  $cd
$1b4e:  ff           DB  $ff
$1b4f:  0a           DB  $0a
$1b50:  0e           DB  $0e
$1b51:  32           DB  $32
$1b52:  cd           DB  $cd
$1b53:  ff           DB  $ff
$1b54:  0a           DB  $0a
$1b55:  c3           DB  $c3
$1b56:  23           DB  $23
$1b57:  1b           DB  $1b
$1b58:  06           DB  $06
$1b59:  08           DB  $08
$1b5a:  3e           DB  $3e
$1b5b:  48           DB  $48
$1b5c:  17           DB  $17
$1b5d:  f5           DB  $f5
$1b5e:  0e           DB  $0e
$1b5f:  30           DB  $30
$1b60:  d2           DB  $d2
$1b61:  65           DB  $65
$1b62:  1b           DB  $1b
$1b63:  0e           DB  $0e
$1b64:  31           DB  $31
$1b65:  cd           DB  $cd
$1b66:  ff           DB  $ff
$1b67:  0a           DB  $0a
$1b68:  05           DB  $05
$1b69:  ca           DB  $ca
$1b6a:  75           DB  $75
$1b6b:  1b           DB  $1b
$1b6c:  0e           DB  $0e
$1b6d:  2c           DB  $2c
$1b6e:  cd           DB  $cd
$1b6f:  ff           DB  $ff
$1b70:  0a           DB  $0a
$1b71:  f1           DB  $f1
$1b72:  c3           DB  $c3
$1b73:  5c           DB  $5c
$1b74:  1b           DB  $1b
$1b75:  f1           DB  $f1
$1b76:  c3           DB  $c3
$1b77:  23           DB  $23
$1b78:  1b           DB  $1b

F_L_1b79:
$1b79:  2a 69 63            LHLD     $6369
$1b7c:  cd 4c 27            CALL     $274c
$1b7f:  2a 6b 63            LHLD     $636b
$1b82:  cd 4c 27            CALL     $274c
$1b85:  2a 6d 63            LHLD     $636d
$1b88:  cd 4c 27            CALL     $274c
$1b8b:  2a 6f 63            LHLD     $636f
$1b8e:  cd 55 27            CALL     $2755
$1b91:  c3 59 1a            JMP      $1a59
$1b94:  3a           DB  $3a
$1b95:  de           DB  $de
$1b96:  63           DB  $63
$1b97:  4f           DB  $4f
$1b98:  cd           DB  $cd
$1b99:  ff           DB  $ff
$1b9a:  0a           DB  $0a
$1b9b:  c3           DB  $c3
$1b9c:  23           DB  $23
$1b9d:  1b           DB  $1b
$1b9e:  21           DB  $21
$1b9f:  00           DB  $00
$1ba0:  00           DB  $00
$1ba1:  cd           DB  $cd
$1ba2:  4c           DB  $4c
$1ba3:  27           DB  $27
$1ba4:  cd           DB  $cd
$1ba5:  4c           DB  $4c
$1ba6:  27           DB  $27
$1ba7:  2a           DB  $2a
$1ba8:  ac           DB  $ac
$1ba9:  63           DB  $63
$1baa:  cd           DB  $cd
$1bab:  4c           DB  $4c
$1bac:  27           DB  $27
$1bad:  2a           DB  $2a
$1bae:  ae           DB  $ae
$1baf:  63           DB  $63
$1bb0:  cd           DB  $cd
$1bb1:  55           DB  $55
$1bb2:  27           DB  $27
$1bb3:  c3           DB  $c3
$1bb4:  59           DB  $59
$1bb5:  1a           DB  $1a
$1bb6:  c3           DB  $c3
$1bb7:  23           DB  $23
$1bb8:  1b           DB  $1b
$1bb9:  c3           DB  $c3
$1bba:  23           DB  $23
$1bbb:  1b           DB  $1b
$1bbc:  e5           DB  $e5
$1bbd:  d5           DB  $d5
$1bbe:  c5           DB  $c5
$1bbf:  21           DB  $21
$1bc0:  30           DB  $30
$1bc1:  75           DB  $75
$1bc2:  22           DB  $22
$1bc3:  e1           DB  $e1
$1bc4:  63           DB  $63
$1bc5:  3e           DB  $3e
$1bc6:  0f           DB  $0f
$1bc7:  32           DB  $32
$1bc8:  e0           DB  $e0
$1bc9:  63           DB  $63
$1bca:  f3           DB  $f3
$1bcb:  2a           DB  $2a
$1bcc:  fa           DB  $fa
$1bcd:  63           DB  $63
$1bce:  7c           DB  $7c
$1bcf:  b5           DB  $b5
$1bd0:  c2           DB  $c2
$1bd1:  d7           DB  $d7
$1bd2:  1b           DB  $1b
$1bd3:  af           DB  $af
$1bd4:  32           DB  $32
$1bd5:  f2           DB  $f2
$1bd6:  63           DB  $63

F_L_1bd7:
$1bd7:  fb                  EI
$1bd8:  3a 00 e0            LDA      $e000
$1bdb:  2f                  CMA
$1bdc:  e6 0f               ANI      $0f
$1bde:  c2 cc 02            JNZ      $02cc

F_L_1be1:
$1be1:  3a f2 63            LDA      $63f2
$1be4:  e6 06               ANI      $06
$1be6:  c2 42 1c            JNZ      $1c42
$1be9:  3a 00 e0            LDA      $e000
$1bec:  e6 40               ANI      $40
$1bee:  c2 f7 1b            JNZ      $1bf7
$1bf1:  21 30 75            LXI      H,$7530
$1bf4:  22 e1 63            SHLD     $63e1

F_L_1bf7:
$1bf7:  11 ff ff            LXI      D,$ffff
$1bfa:  2a e1 63            LHLD     $63e1
$1bfd:  19                  DAD      D
$1bfe:  22 e1 63            SHLD     $63e1
$1c01:  da d7 1b            JC       $1bd7
$1c04:  21 30 75            LXI      H,$7530
$1c07:  22 e1 63            SHLD     $63e1
$1c0a:  3e 0b               MVI      A,$0b
$1c0c:  32 03 e4            STA      $e403
$1c0f:  3a f0 63            LDA      $63f0
$1c12:  f6 20               ORI      $20
$1c14:  32 f0 63            STA      $63f0
$1c17:  cd 3c 22            CALL     $223c
$1c1a:  21 e0 63            LXI      H,$63e0
$1c1d:  35                  DCR      M
$1c1e:  c2 d7 1b            JNZ      $1bd7
$1c21:  1e 0f               MVI      E,$0f
$1c23:  3a f0 63            LDA      $63f0
$1c26:  47                  MOV      B,A
$1c27:  e6 40               ANI      $40
$1c29:  c2 d7 1b            JNZ      $1bd7
$1c2c:  3e 40               MVI      A,$40
$1c2e:  b0                  ORA      B
$1c2f:  32 f0 63            STA      $63f0
$1c32:  0e 13               MVI      C,$13
$1c34:  cd e0 0a            CALL     $0ae0
$1c37:  cd 11 09            CALL     $0911
$1c3a:  0e 11               MVI      C,$11
$1c3c:  cd e0 0a            CALL     $0ae0
$1c3f:  c3 d7 1b            JMP      $1bd7

F_L_1c42:
$1c42:  f3                  DI
$1c43:  2a fa 63            LHLD     $63fa
$1c46:  2b                  DCX      H
$1c47:  22 fa 63            SHLD     $63fa
$1c4a:  fb                  EI
$1c4b:  11 83 03            LXI      D,$0383
$1c4e:  cd ea 27            CALL     $27ea
$1c51:  d2 68 1c            JNC      $1c68
$1c54:  3a f2 63            LDA      $63f2
$1c57:  47                  MOV      B,A
$1c58:  e6 01               ANI      $01
$1c5a:  ca 68 1c            JZ       $1c68
$1c5d:  78                  MOV      A,B
$1c5e:  e6 fe               ANI      $fe
$1c60:  32 f2 63            STA      $63f2
$1c63:  0e 11               MVI      C,$11
$1c65:  cd e0 0a            CALL     $0ae0

F_L_1c68:
$1c68:  2a f6 63            LHLD     $63f6
$1c6b:  46                  MOV      B,M
$1c6c:  36 00               MVI      M,$00
$1c6e:  11 e4 67            LXI      D,$67e4
$1c71:  cd ea 27            CALL     $27ea
$1c74:  23                  INX      H
$1c75:  c2 7b 1c            JNZ      $1c7b
$1c78:  21 fd 63            LXI      H,$63fd

F_L_1c7b:
$1c7b:  22 f6 63            SHLD     $63f6
$1c7e:  3e 0a               MVI      A,$0a
$1c80:  32 03 e4            STA      $e403
$1c83:  c5                  PUSH     B
$1c84:  3a f0 63            LDA      $63f0
$1c87:  47                  MOV      B,A
$1c88:  e6 20               ANI      $20
$1c8a:  ca 9b 1c            JZ       $1c9b
$1c8d:  78                  MOV      A,B
$1c8e:  e6 df               ANI      $df
$1c90:  32 f0 63            STA      $63f0
$1c93:  e6 02               ANI      $02
$1c95:  ca 9b 1c            JZ       $1c9b
$1c98:  cd 16 22            CALL     $2216

F_L_1c9b:
$1c9b:  3a f0 63            LDA      $63f0
$1c9e:  47                  MOV      B,A
$1c9f:  e6 40               ANI      $40
$1ca1:  ca ad 1c            JZ       $1cad
$1ca4:  3e bf               MVI      A,$bf
$1ca6:  a0                  ANA      B
$1ca7:  32 f0 63            STA      $63f0
$1caa:  cd 11 09            CALL     $0911

F_L_1cad:
$1cad:  c1                  POP      B
$1cae:  3a f0 63            LDA      $63f0
$1cb1:  e6 80               ANI      $80
$1cb3:  78                  MOV      A,B
$1cb4:  c2 b9 1c            JNZ      $1cb9
$1cb7:  e6 7f               ANI      $7f

F_L_1cb9:
$1cb9:  32 48 61            STA      $6148
$1cbc:  c1                  POP      B
$1cbd:  d1                  POP      D
$1cbe:  e1                  POP      H
$1cbf:  c9                  RET
$1cc0:  7a                  MOV      A,D
$1cc1:  a7                  ANA      A
$1cc2:  c2 dc 1c            JNZ      $1cdc
$1cc5:  7b                  MOV      A,E
$1cc6:  a7                  ANA      A
$1cc7:  fa dc 1c            JM       $1cdc
$1cca:  53                  MOV      D,E
$1ccb:  5c                  MOV      E,H
$1ccc:  21 cd 00            LXI      H,$00cd
$1ccf:  cd 57 29            CALL     $2957
$1cd2:  6c                  MOV      L,H
$1cd3:  63                  MOV      H,E
$1cd4:  11 3c 00            LXI      D,$003c
$1cd7:  cd 27 29            CALL     $2927
$1cda:  eb                  XCHG
$1cdb:  c9                  RET

F_L_1cdc:
$1cdc:  21 00 00            LXI      H,$0000
$1cdf:  c9                  RET

F_L_1ce0:
$1ce0:  2a 5d 63            LHLD     $635d
$1ce3:  3a 8b 63            LDA      $638b
$1ce6:  e6 02               ANI      $02
$1ce8:  ca fa 1c            JZ       $1cfa
$1ceb:  eb                  XCHG
$1cec:  2a 4e 63            LHLD     $634e
$1cef:  cd b4 28            CALL     $28b4
$1cf2:  7c                  MOV      A,H
$1cf3:  a7                  ANA      A
$1cf4:  f2 fa 1c            JP       $1cfa
$1cf7:  21 00 00            LXI      H,$0000

F_L_1cfa:
$1cfa:  22 5d 63            SHLD     $635d
$1cfd:  2a 5f 63            LHLD     $635f
$1d00:  3a 8b 63            LDA      $638b
$1d03:  e6 02               ANI      $02
$1d05:  ca 17 1d            JZ       $1d17
$1d08:  eb                  XCHG
$1d09:  2a 50 63            LHLD     $6350
$1d0c:  cd b4 28            CALL     $28b4
$1d0f:  7c                  MOV      A,H
$1d10:  a7                  ANA      A
$1d11:  f2 17 1d            JP       $1d17
$1d14:  21 00 00            LXI      H,$0000

F_L_1d17:
$1d17:  22 5f 63            SHLD     $635f
$1d1a:  3a 68 62            LDA      $6268
$1d1d:  a7                  ANA      A
$1d1e:  ca 76 1e            JZ       $1e76
$1d21:  47                  MOV      B,A
$1d22:  3a 2f 63            LDA      $632f
$1d25:  a7                  ANA      A
$1d26:  ca 76 1e            JZ       $1e76
$1d29:  2a 5d 63            LHLD     $635d
$1d2c:  22 6e 62            SHLD     $626e
$1d2f:  2a 5f 63            LHLD     $635f
$1d32:  22 70 62            SHLD     $6270
$1d35:  78                  MOV      A,B
$1d36:  e6 40               ANI      $40
$1d38:  78                  MOV      A,B
$1d39:  ca 57 1d            JZ       $1d57
$1d3c:  21 f4 21            LXI      H,$21f4
$1d3f:  e6 0f               ANI      $0f
$1d41:  3d                  DCR      A
$1d42:  16 00               MVI      D,$00
$1d44:  87                  ADD      A
$1d45:  5f                  MOV      E,A
$1d46:  19                  DAD      D
$1d47:  5e                  MOV      E,M
$1d48:  23                  INX      H
$1d49:  56                  MOV      D,M
$1d4a:  eb                  XCHG
$1d4b:  22 7c 62            SHLD     $627c
$1d4e:  3e bf               MVI      A,$bf
$1d50:  a0                  ANA      B
$1d51:  32 68 62            STA      $6268
$1d54:  c3 6c 1d            JMP      $1d6c

F_L_1d57:
$1d57:  2a 6c 62            LHLD     $626c
$1d5a:  7c                  MOV      A,H
$1d5b:  b5                  ORA      L
$1d5c:  c2 81 1d            JNZ      $1d81

F_L_1d5f:
$1d5f:  2a 7a 62            LHLD     $627a
$1d62:  7e                  MOV      A,M
$1d63:  47                  MOV      B,A
$1d64:  23                  INX      H
$1d65:  a7                  ANA      A
$1d66:  f2 6c 1d            JP       $1d6c
$1d69:  2a 7c 62            LHLD     $627c

F_L_1d6c:
$1d6c:  22 7a 62            SHLD     $627a
$1d6f:  2a 7a 62            LHLD     $627a
$1d72:  7e                  MOV      A,M
$1d73:  e6 3f               ANI      $3f
$1d75:  5f                  MOV      E,A
$1d76:  16 00               MVI      D,$00
$1d78:  2a 6a 62            LHLD     $626a
$1d7b:  cd 57 29            CALL     $2957
$1d7e:  22 6c 62            SHLD     $626c

F_L_1d81:
$1d81:  2a 50 63            LHLD     $6350
$1d84:  eb                  XCHG
$1d85:  2a 70 62            LHLD     $6270
$1d88:  cd a6 28            CALL     $28a6
$1d8b:  22 74 62            SHLD     $6274
$1d8e:  2a 4e 63            LHLD     $634e
$1d91:  eb                  XCHG
$1d92:  2a 6e 62            LHLD     $626e
$1d95:  cd a6 28            CALL     $28a6
$1d98:  22 72 62            SHLD     $6272
$1d9b:  eb                  XCHG
$1d9c:  2a 74 62            LHLD     $6274
$1d9f:  cd 77 43            CALL     $4377
$1da2:  2a a9 61            LHLD     $61a9
$1da5:  44                  MOV      B,H
$1da6:  4d                  MOV      C,L
$1da7:  2a a7 61            LHLD     $61a7
$1daa:  eb                  XCHG
$1dab:  2a 6c 62            LHLD     $626c
$1dae:  cd 21 28            CALL     $2821
$1db1:  22 76 62            SHLD     $6276
$1db4:  2a a5 61            LHLD     $61a5
$1db7:  44                  MOV      B,H
$1db8:  4d                  MOV      C,L
$1db9:  2a a3 61            LHLD     $61a3
$1dbc:  eb                  XCHG
$1dbd:  2a 6c 62            LHLD     $626c
$1dc0:  cd 21 28            CALL     $2821
$1dc3:  22 78 62            SHLD     $6278
$1dc6:  2a 76 62            LHLD     $6276
$1dc9:  eb                  XCHG
$1dca:  2a 4e 63            LHLD     $634e
$1dcd:  cd b4 28            CALL     $28b4
$1dd0:  22 5d 63            SHLD     $635d
$1dd3:  2a 78 62            LHLD     $6278
$1dd6:  eb                  XCHG
$1dd7:  2a 50 63            LHLD     $6350
$1dda:  cd b4 28            CALL     $28b4
$1ddd:  22 5f 63            SHLD     $635f
$1de0:  2a 7a 62            LHLD     $627a
$1de3:  7e                  MOV      A,M
$1de4:  e6 40               ANI      $40
$1de6:  3e ff               MVI      A,$ff
$1de8:  c2 ec 1d            JNZ      $1dec
$1deb:  af                  XRA      A

F_L_1dec:
$1dec:  32 2f 63            STA      $632f
$1def:  2a 76 62            LHLD     $6276
$1df2:  eb                  XCHG
$1df3:  2a 72 62            LHLD     $6272
$1df6:  cd e2 27            CALL     $27e2
$1df9:  da 0f 1e            JC       $1e0f
$1dfc:  2a 78 62            LHLD     $6278
$1dff:  eb                  XCHG
$1e00:  2a 74 62            LHLD     $6274
$1e03:  cd e2 27            CALL     $27e2
$1e06:  da 0f 1e            JC       $1e0f
$1e09:  cd 76 1e            CALL     $1e76
$1e0c:  c3 5f 1d            JMP      $1d5f

F_L_1e0f:
$1e0f:  2a 6e 62            LHLD     $626e
$1e12:  22 5d 63            SHLD     $635d
$1e15:  2a 70 62            LHLD     $6270
$1e18:  22 5f 63            SHLD     $635f
$1e1b:  2a 74 62            LHLD     $6274
$1e1e:  eb                  XCHG
$1e1f:  2a 72 62            LHLD     $6272
$1e22:  cd e2 27            CALL     $27e2
$1e25:  2a 72 62            LHLD     $6272
$1e28:  eb                  XCHG
$1e29:  2a 76 62            LHLD     $6276
$1e2c:  3e ff               MVI      A,$ff
$1e2e:  da 39 1e            JC       $1e39
$1e31:  2a 74 62            LHLD     $6274
$1e34:  eb                  XCHG
$1e35:  2a 78 62            LHLD     $6278
$1e38:  af                  XRA      A

F_L_1e39:
$1e39:  f5                  PUSH     PSW
$1e3a:  cd a6 28            CALL     $28a6
$1e3d:  7c                  MOV      A,H
$1e3e:  e6 7f               ANI      $7f
$1e40:  67                  MOV      H,A
$1e41:  f1                  POP      PSW
$1e42:  a7                  ANA      A
$1e43:  ca 54 1e            JZ       $1e54
$1e46:  3a a9 61            LDA      $61a9
$1e49:  a7                  ANA      A
$1e4a:  c2 6d 1e            JNZ      $1e6d
$1e4d:  eb                  XCHG
$1e4e:  2a a7 61            LHLD     $61a7
$1e51:  c3 5f 1e            JMP      $1e5f

F_L_1e54:
$1e54:  3a a5 61            LDA      $61a5
$1e57:  a7                  ANA      A
$1e58:  c2 6d 1e            JNZ      $1e6d
$1e5b:  eb                  XCHG
$1e5c:  2a a3 61            LHLD     $61a3

F_L_1e5f:
$1e5f:  cd 29 2c            CALL     $2c29
$1e62:  eb                  XCHG
$1e63:  cd 27 29            CALL     $2927
$1e66:  eb                  XCHG
$1e67:  cd 29 2c            CALL     $2c29
$1e6a:  22 6c 62            SHLD     $626c

F_L_1e6d:
$1e6d:  cd 76 1e            CALL     $1e76
$1e70:  3e ff               MVI      A,$ff
$1e72:  32 2f 63            STA      $632f
$1e75:  c9                  RET

F_L_1e76:
$1e76:  2a 5d 63            LHLD     $635d
$1e79:  22 4e 63            SHLD     $634e
$1e7c:  44                  MOV      B,H
$1e7d:  4d                  MOV      C,L
$1e7e:  2a 93 63            LHLD     $6393
$1e81:  eb                  XCHG
$1e82:  2a 91 63            LHLD     $6391
$1e85:  cd 38 28            CALL     $2838
$1e88:  42                  MOV      B,D
$1e89:  4b                  MOV      C,E
$1e8a:  11 fd 8a            LXI      D,$8afd
$1e8d:  19                  DAD      D
$1e8e:  69                  MOV      L,C
$1e8f:  60                  MOV      H,B
$1e90:  11 00 00            LXI      D,$0000
$1e93:  cd 9f 28            CALL     $289f
$1e96:  22 56 63            SHLD     $6356
$1e99:  2a 5f 63            LHLD     $635f
$1e9c:  22 50 63            SHLD     $6350
$1e9f:  44                  MOV      B,H
$1ea0:  4d                  MOV      C,L
$1ea1:  2a 97 63            LHLD     $6397
$1ea4:  eb                  XCHG
$1ea5:  2a 95 63            LHLD     $6395
$1ea8:  cd 38 28            CALL     $2838
$1eab:  42                  MOV      B,D
$1eac:  4b                  MOV      C,E
$1ead:  11 fd 8a            LXI      D,$8afd
$1eb0:  19                  DAD      D
$1eb1:  69                  MOV      L,C
$1eb2:  60                  MOV      H,B
$1eb3:  11 00 00            LXI      D,$0000
$1eb6:  cd 9f 28            CALL     $289f
$1eb9:  22 58 63            SHLD     $6358
$1ebc:  eb                  XCHG
$1ebd:  2a 56 63            LHLD     $6356
$1ec0:  3a 8b 63            LDA      $638b
$1ec3:  e6 04               ANI      $04
$1ec5:  ca c9 1e            JZ       $1ec9
$1ec8:  eb                  XCHG

F_L_1ec9:
$1ec9:  22 56 63            SHLD     $6356
$1ecc:  eb                  XCHG
$1ecd:  22 58 63            SHLD     $6358
$1ed0:  3a 8b 63            LDA      $638b
$1ed3:  17                  RAL
$1ed4:  da e9 1e            JC       $1ee9
$1ed7:  2a 7b 63            LHLD     $637b
$1eda:  cd 9f 28            CALL     $289f
$1edd:  f2 f5 1e            JP       $1ef5
$1ee0:  da f5 1e            JC       $1ef5
$1ee3:  21 ff 7f            LXI      H,$7fff
$1ee6:  c3 f5 1e            JMP      $1ef5

F_L_1ee9:
$1ee9:  2a 7f 63            LHLD     $637f
$1eec:  cd f0 27            CALL     $27f0
$1eef:  d2 f5 1e            JNC      $1ef5
$1ef2:  21 00 00            LXI      H,$0000

F_L_1ef5:
$1ef5:  22 56 63            SHLD     $6356
$1ef8:  2a 58 63            LHLD     $6358
$1efb:  eb                  XCHG
$1efc:  3a 8b 63            LDA      $638b
$1eff:  1f                  RAR
$1f00:  da 12 1f            JC       $1f12
$1f03:  2a 7b 63            LHLD     $637b
$1f06:  cd 9f 28            CALL     $289f
$1f09:  f2 1e 1f            JP       $1f1e
$1f0c:  21 ff 7f            LXI      H,$7fff
$1f0f:  c3 1e 1f            JMP      $1f1e

F_L_1f12:
$1f12:  2a 81 63            LHLD     $6381
$1f15:  cd f0 27            CALL     $27f0
$1f18:  d2 1e 1f            JNC      $1f1e
$1f1b:  21 00 00            LXI      H,$0000

F_L_1f1e:
$1f1e:  22 58 63            SHLD     $6358
$1f21:  2a 52 63            LHLD     $6352
$1f24:  eb                  XCHG
$1f25:  2a 56 63            LHLD     $6356
$1f28:  cd ea 27            CALL     $27ea
$1f2b:  3e 00               MVI      A,$00
$1f2d:  d2 32 1f            JNC      $1f32
$1f30:  3e ff               MVI      A,$ff

F_L_1f32:
$1f32:  32 5b 63            STA      $635b
$1f35:  2a 54 63            LHLD     $6354
$1f38:  eb                  XCHG
$1f39:  2a 58 63            LHLD     $6358
$1f3c:  cd ea 27            CALL     $27ea
$1f3f:  3e 00               MVI      A,$00
$1f41:  d2 46 1f            JNC      $1f46
$1f44:  3e ff               MVI      A,$ff

F_L_1f46:
$1f46:  32 5c 63            STA      $635c
$1f49:  3a 40 63            LDA      $6340
$1f4c:  a7                  ANA      A
$1f4d:  ca 61 1f            JZ       $1f61
$1f50:  2a 52 63            LHLD     $6352
$1f53:  cd 0f 20            CALL     $200f
$1f56:  2a 54 63            LHLD     $6354
$1f59:  cd 2c 20            CALL     $202c
$1f5c:  79                  MOV      A,C
$1f5d:  b0                  ORA      B
$1f5e:  32 4d 63            STA      $634d

F_L_1f61:
$1f61:  2a 56 63            LHLD     $6356
$1f64:  cd 0f 20            CALL     $200f
$1f67:  2a 58 63            LHLD     $6358
$1f6a:  cd 2c 20            CALL     $202c
$1f6d:  79                  MOV      A,C
$1f6e:  b0                  ORA      B
$1f6f:  32 5a 63            STA      $635a
$1f72:  c2 82 1f            JNZ      $1f82
$1f75:  3a 4d 63            LDA      $634d
$1f78:  a7                  ANA      A
$1f79:  c2 a5 1f            JNZ      $1fa5
$1f7c:  cd 96 20            CALL     $2096
$1f7f:  c3 92 1f            JMP      $1f92

F_L_1f82:
$1f82:  3a 4d 63            LDA      $634d
$1f85:  a7                  ANA      A
$1f86:  c2 b7 1f            JNZ      $1fb7
$1f89:  3a 5a 63            LDA      $635a
$1f8c:  cd 65 21            CALL     $2165
$1f8f:  c3 a8 20            JMP      $20a8

F_L_1f92:
$1f92:  2a 56 63            LHLD     $6356
$1f95:  22 52 63            SHLD     $6352
$1f98:  2a 58 63            LHLD     $6358
$1f9b:  22 54 63            SHLD     $6354
$1f9e:  3a 5a 63            LDA      $635a
$1fa1:  32 4d 63            STA      $634d
$1fa4:  c9                  RET

F_L_1fa5:
$1fa5:  cd 65 21            CALL     $2165
$1fa8:  2a 56 63            LHLD     $6356
$1fab:  22 65 63            SHLD     $6365
$1fae:  2a 58 63            LHLD     $6358
$1fb1:  22 67 63            SHLD     $6367
$1fb4:  c3 be 20            JMP      $20be

F_L_1fb7:
$1fb7:  47                  MOV      B,A
$1fb8:  e6 f0               ANI      $f0
$1fba:  57                  MOV      D,A
$1fbb:  ca f5 1f            JZ       $1ff5
$1fbe:  78                  MOV      A,B
$1fbf:  e6 0f               ANI      $0f
$1fc1:  5f                  MOV      E,A
$1fc2:  3a 5a 63            LDA      $635a
$1fc5:  4f                  MOV      C,A
$1fc6:  ca 06 20            JZ       $2006
$1fc9:  e6 f0               ANI      $f0
$1fcb:  ba                  CMP      D
$1fcc:  ca 92 1f            JZ       $1f92
$1fcf:  79                  MOV      A,C
$1fd0:  e6 0f               ANI      $0f
$1fd2:  bb                  CMP      E
$1fd3:  ca 92 1f            JZ       $1f92

F_L_1fd6:
$1fd6:  79                  MOV      A,C
$1fd7:  cd 65 21            CALL     $2165
$1fda:  c2 92 1f            JNZ      $1f92
$1fdd:  2a 61 63            LHLD     $6361
$1fe0:  22 65 63            SHLD     $6365
$1fe3:  2a 63 63            LHLD     $6363
$1fe6:  22 67 63            SHLD     $6367
$1fe9:  3a 4d 63            LDA      $634d
$1fec:  cd 65 21            CALL     $2165
$1fef:  c2 92 1f            JNZ      $1f92
$1ff2:  c3 be 20            JMP      $20be

F_L_1ff5:
$1ff5:  3a 5a 63            LDA      $635a
$1ff8:  4f                  MOV      C,A
$1ff9:  e6 0f               ANI      $0f
$1ffb:  57                  MOV      D,A
$1ffc:  78                  MOV      A,B
$1ffd:  e6 0f               ANI      $0f
$1fff:  ba                  CMP      D
$2000:  ca 92 1f            JZ       $1f92
$2003:  c3 d6 1f            JMP      $1fd6

F_M_2006:
$2006:  e6 f0               ANI      $f0
$2008:  ba                  CMP      D
$2009:  ca 92 1f            JZ       $1f92
$200c:  c3 d6 1f            JMP      $1fd6

F_M_200f:
$200f:  eb                  XCHG
$2010:  2a 6d 63            LHLD     $636d
$2013:  cd ea 27            CALL     $27ea
$2016:  06 20               MVI      B,$20
$2018:  da 29 20            JC       $2029
$201b:  2a 69 63            LHLD     $6369
$201e:  eb                  XCHG
$201f:  cd ea 27            CALL     $27ea
$2022:  06 10               MVI      B,$10
$2024:  da 29 20            JC       $2029
$2027:  06 00               MVI      B,$00

F_M_2029:
$2029:  af                  XRA      A
$202a:  b0                  ORA      B
$202b:  c9                  RET

F_M_202c:
$202c:  eb                  XCHG
$202d:  2a 6f 63            LHLD     $636f
$2030:  cd ea 27            CALL     $27ea
$2033:  0e 02               MVI      C,$02
$2035:  da 46 20            JC       $2046
$2038:  2a 6b 63            LHLD     $636b
$203b:  eb                  XCHG
$203c:  cd ea 27            CALL     $27ea
$203f:  0e 01               MVI      C,$01
$2041:  da 46 20            JC       $2046
$2044:  0e 00               MVI      C,$00

F_M_2046:
$2046:  af                  XRA      A
$2047:  b1                  ORA      C
$2048:  c9                  RET

F_M_2049:
$2049:  f5                  PUSH     PSW
$204a:  2a 52 63            LHLD     $6352
$204d:  eb                  XCHG
$204e:  2a 56 63            LHLD     $6356
$2051:  cd ea 27            CALL     $27ea
$2054:  d2 58 20            JNC      $2058
$2057:  eb                  XCHG

F_M_2058:
$2058:  cd f0 27            CALL     $27f0
$205b:  22 3c 63            SHLD     $633c
$205e:  2a 54 63            LHLD     $6354
$2061:  eb                  XCHG
$2062:  2a 58 63            LHLD     $6358
$2065:  cd ea 27            CALL     $27ea
$2068:  d2 6c 20            JNC      $206c
$206b:  eb                  XCHG

F_M_206c:
$206c:  cd f0 27            CALL     $27f0
$206f:  22 3e 63            SHLD     $633e
$2072:  eb                  XCHG
$2073:  2a 3c 63            LHLD     $633c
$2076:  cd e3 28            CALL     $28e3
$2079:  22 44 63            SHLD     $6344
$207c:  eb                  XCHG
$207d:  22 46 63            SHLD     $6346
$2080:  f1                  POP      PSW
$2081:  c9                  RET

F_M_2082:
$2082:  f5                  PUSH     PSW
$2083:  2a 3c 63            LHLD     $633c
$2086:  eb                  XCHG
$2087:  2a 3e 63            LHLD     $633e
$208a:  cd e3 28            CALL     $28e3
$208d:  22 48 63            SHLD     $6348
$2090:  eb                  XCHG
$2091:  22 4a 63            SHLD     $634a
$2094:  f1                  POP      PSW
$2095:  c9                  RET

F_M_2096:
$2096:  2a 56 63            LHLD     $6356
$2099:  22 bd 63            SHLD     $63bd
$209c:  2a 58 63            LHLD     $6358
$209f:  22 bf 63            SHLD     $63bf
$20a2:  cd 52 22            CALL     $2252
$20a5:  c3 92 1f            JMP      $1f92

F_M_20a8:
$20a8:  2a 61 63            LHLD     $6361
$20ab:  22 bd 63            SHLD     $63bd
$20ae:  2a 63 63            LHLD     $6363
$20b1:  22 bf 63            SHLD     $63bf
$20b4:  cd 52 22            CALL     $2252
$20b7:  af                  XRA      A
$20b8:  32 2f 63            STA      $632f
$20bb:  c3 92 1f            JMP      $1f92

F_M_20be:
$20be:  af                  XRA      A
$20bf:  32 2f 63            STA      $632f
$20c2:  2a 61 63            LHLD     $6361
$20c5:  22 bd 63            SHLD     $63bd
$20c8:  2a 63 63            LHLD     $6363
$20cb:  22 bf 63            SHLD     $63bf
$20ce:  cd 52 22            CALL     $2252
$20d1:  3a 5b 62            LDA      $625b
$20d4:  32 2f 63            STA      $632f
$20d7:  2a 65 63            LHLD     $6365
$20da:  22 bd 63            SHLD     $63bd
$20dd:  2a 67 63            LHLD     $6367
$20e0:  22 bf 63            SHLD     $63bf
$20e3:  cd 52 22            CALL     $2252
$20e6:  c3 92 1f            JMP      $1f92

F_M_20e9:
$20e9:  3a 5b 63            LDA      $635b
$20ec:  4f                  MOV      C,A
$20ed:  2a 52 63            LHLD     $6352
$20f0:  22 71 63            SHLD     $6371
$20f3:  2a 54 63            LHLD     $6354
$20f6:  eb                  XCHG
$20f7:  2a 6b 63            LHLD     $636b
$20fa:  22 63 63            SHLD     $6363
$20fd:  3e 00               MVI      A,$00
$20ff:  cd af 21            CALL     $21af
$2102:  22 61 63            SHLD     $6361
$2105:  c3 0f 20            JMP      $200f

F_M_2108:
$2108:  3a 5b 63            LDA      $635b
$210b:  4f                  MOV      C,A
$210c:  2a 52 63            LHLD     $6352
$210f:  22 71 63            SHLD     $6371
$2112:  2a 54 63            LHLD     $6354
$2115:  eb                  XCHG
$2116:  2a 6f 63            LHLD     $636f
$2119:  22 63 63            SHLD     $6363
$211c:  3e 00               MVI      A,$00
$211e:  cd af 21            CALL     $21af
$2121:  22 61 63            SHLD     $6361
$2124:  c3 0f 20            JMP      $200f

F_M_2127:
$2127:  3a 5c 63            LDA      $635c
$212a:  4f                  MOV      C,A
$212b:  2a 54 63            LHLD     $6354
$212e:  22 71 63            SHLD     $6371
$2131:  2a 52 63            LHLD     $6352
$2134:  eb                  XCHG
$2135:  2a 69 63            LHLD     $6369
$2138:  22 61 63            SHLD     $6361
$213b:  3e ff               MVI      A,$ff
$213d:  cd af 21            CALL     $21af
$2140:  22 63 63            SHLD     $6363
$2143:  c3 2c 20            JMP      $202c

F_M_2146:
$2146:  3a 5c 63            LDA      $635c
$2149:  4f                  MOV      C,A
$214a:  2a 54 63            LHLD     $6354
$214d:  22 71 63            SHLD     $6371
$2150:  2a 52 63            LHLD     $6352
$2153:  eb                  XCHG
$2154:  2a 6d 63            LHLD     $636d
$2157:  22 61 63            SHLD     $6361
$215a:  3e ff               MVI      A,$ff
$215c:  cd af 21            CALL     $21af
$215f:  22 63 63            SHLD     $6363
$2162:  c3 2c 20            JMP      $202c

F_M_2165:
$2165:  cd 49 20            CALL     $2049
$2168:  fe 01               CPI      $01
$216a:  ca e9 20            JZ       $20e9
$216d:  fe 02               CPI      $02
$216f:  ca 08 21            JZ       $2108
$2172:  cd 82 20            CALL     $2082
$2175:  fe 10               CPI      $10
$2177:  ca 27 21            JZ       $2127
$217a:  fe 20               CPI      $20
$217c:  ca 46 21            JZ       $2146
$217f:  fe 11               CPI      $11
$2181:  ca 93 21            JZ       $2193
$2184:  fe 12               CPI      $12
$2186:  ca 9a 21            JZ       $219a
$2189:  fe 21               CPI      $21
$218b:  ca a1 21            JZ       $21a1
$218e:  fe 22               CPI      $22
$2190:  c3 a8 21            JMP      $21a8

F_M_2193:
$2193:  cd 27 21            CALL     $2127
$2196:  c2 e9 20            JNZ      $20e9
$2199:  c9                  RET

F_M_219a:
$219a:  cd 27 21            CALL     $2127
$219d:  c2 08 21            JNZ      $2108
$21a0:  c9                  RET

F_M_21a1:
$21a1:  cd 46 21            CALL     $2146
$21a4:  c2 e9 20            JNZ      $20e9
$21a7:  c9                  RET

F_M_21a8:
$21a8:  cd 46 21            CALL     $2146
$21ab:  c2 08 21            JNZ      $2108
$21ae:  c9                  RET

F_M_21af:
$21af:  32 42 63            STA      $6342
$21b2:  79                  MOV      A,C
$21b3:  32 41 63            STA      $6341
$21b6:  cd ea 27            CALL     $27ea
$21b9:  ca f0 21            JZ       $21f0
$21bc:  d2 c0 21            JNC      $21c0
$21bf:  eb                  XCHG

F_M_21c0:
$21c0:  cd f0 27            CALL     $27f0
$21c3:  44                  MOV      B,H
$21c4:  4d                  MOV      C,L
$21c5:  3a 42 63            LDA      $6342
$21c8:  a7                  ANA      A
$21c9:  ca d6 21            JZ       $21d6
$21cc:  2a 4a 63            LHLD     $634a
$21cf:  eb                  XCHG
$21d0:  2a 48 63            LHLD     $6348
$21d3:  c3 dd 21            JMP      $21dd

F_M_21d6:
$21d6:  2a 46 63            LHLD     $6346
$21d9:  eb                  XCHG
$21da:  2a 44 63            LHLD     $6344

F_M_21dd:
$21dd:  cd 78 28            CALL     $2878
$21e0:  2a 71 63            LHLD     $6371
$21e3:  3a 41 63            LDA      $6341
$21e6:  a7                  ANA      A
$21e7:  ca ee 21            JZ       $21ee
$21ea:  cd f0 27            CALL     $27f0
$21ed:  c9                  RET

F_M_21ee:
$21ee:  19                  DAD      D
$21ef:  c9                  RET

F_M_21f0:
$21f0:  2a 71 63            LHLD     $6371
$21f3:  c9                  RET
$21f4:  00                  NOP
$21f5:  22 04 22            SHLD     $2204
$21f8:  06 22               MVI      B,$22
$21fa:  08                  NOP
$21fb:  22 0c 22            SHLD     $220c
$21fe:  10                  NOP
$21ff:  22 40 00            SHLD     $0040
$2202:  bc                  CMP      H
$2203:  00                  NOP
$2204:  5e                  MOV      E,M
$2205:  9e                  SBB      M
$2206:  6a                  MOV      L,D
$2207:  92                  SUB      D
$2208:  6a                  MOV      L,D
$2209:  09                  DAD      B
$220a:  40                  NOP
$220b:  89                  ADC      C
$220c:  6a                  MOV      L,D
$220d:  06 46               MVI      B,$46
$220f:  86                  ADD      M
$2210:  64                  NOP
$2211:  04                  INR      B
$2212:  44                  MOV      B,H
$2213:  04                  INR      B
$2214:  44                  MOV      B,H
$2215:  84                  ADD      H

F_M_2216:
$2216:  e5                  PUSH     H
$2217:  c5                  PUSH     B
$2218:  21 03 e4            LXI      H,$e403
$221b:  36 01               MVI      M,$01
$221d:  36 03               MVI      M,$03
$221f:  06 1b               MVI      B,$1b

F_M_2221:
$2221:  0e 2d               MVI      C,$2d

F_M_2223:
$2223:  0d                  DCR      C
$2224:  c2 23 22            JNZ      $2223
$2227:  05                  DCR      B
$2228:  c2 21 22            JNZ      $2221
$222b:  36 00               MVI      M,$00
$222d:  06 37               MVI      B,$37

F_M_222f:
$222f:  0e 3c               MVI      C,$3c

F_M_2231:
$2231:  0d                  DCR      C
$2232:  c2 31 22            JNZ      $2231
$2235:  05                  DCR      B
$2236:  c2 2f 22            JNZ      $222f
$2239:  c1                  POP      B
$223a:  e1                  POP      H
$223b:  c9                  RET

F_M_223c:
$223c:  e5                  PUSH     H
$223d:  c5                  PUSH     B
$223e:  21 03 e4            LXI      H,$e403
$2241:  36 02               MVI      M,$02
$2243:  06 28               MVI      B,$28

F_M_2245:
$2245:  0e 28               MVI      C,$28

F_M_2247:
$2247:  0d                  DCR      C
$2248:  c2 47 22            JNZ      $2247
$224b:  05                  DCR      B
$224c:  c2 45 22            JNZ      $2245
$224f:  c1                  POP      B
$2250:  e1                  POP      H
$2251:  c9                  RET

F_M_2252:
$2252:  3e 63               MVI      A,$63
$2254:  32 b7 63            STA      $63b7
$2257:  3a 57 62            LDA      $6257
$225a:  32 58 62            STA      $6258
$225d:  21 dc ff            LXI      H,$ffdc
$2260:  11 ff ff            LXI      D,$ffff
$2263:  06 04               MVI      B,$04

F_M_2265:
$2265:  19                  DAD      D
$2266:  3e 03               MVI      A,$03
$2268:  da 6f 22            JC       $226f
$226b:  05                  DCR      B
$226c:  ca 29 02            JZ       $0229

F_M_226f:
$226f:  3a 00 e0            LDA      $e000
$2272:  e6 40               ANI      $40
$2274:  ca 65 22            JZ       $2265
$2277:  21 02 e8            LXI      H,$e802
$227a:  5e                  MOV      E,M
$227b:  56                  MOV      D,M
$227c:  2a 7a 61            LHLD     $617a
$227f:  19                  DAD      D
$2280:  3a b2 63            LDA      $63b2
$2283:  47                  MOV      B,A
$2284:  2f                  CMA
$2285:  e6 03               ANI      $03
$2287:  ca ba 22            JZ       $22ba
$228a:  78                  MOV      A,B
$228b:  e6 0c               ANI      $0c
$228d:  c2 ba 22            JNZ      $22ba
$2290:  78                  MOV      A,B
$2291:  e6 01               ANI      $01
$2293:  78                  MOV      A,B
$2294:  c2 aa 22            JNZ      $22aa
$2297:  e6 20               ANI      $20
$2299:  c2 9f 22            JNZ      $229f
$229c:  cd db 28            CALL     $28db

F_M_229f:
$229f:  eb                  XCHG
$22a0:  2a 9b 63            LHLD     $639b
$22a3:  19                  DAD      D
$22a4:  22 9b 63            SHLD     $639b
$22a7:  c3 ba 22            JMP      $22ba

F_M_22aa:
$22aa:  e6 40               ANI      $40
$22ac:  c2 b2 22            JNZ      $22b2
$22af:  cd db 28            CALL     $28db

F_M_22b2:
$22b2:  eb                  XCHG
$22b3:  2a 9d 63            LHLD     $639d
$22b6:  19                  DAD      D
$22b7:  22 9d 63            SHLD     $639d

F_M_22ba:
$22ba:  2a bd 63            LHLD     $63bd
$22bd:  7c                  MOV      A,H
$22be:  a7                  ANA      A
$22bf:  f2 c8 22            JP       $22c8
$22c2:  21 00 00            LXI      H,$0000
$22c5:  c3 d3 22            JMP      $22d3

F_M_22c8:
$22c8:  eb                  XCHG
$22c9:  2a ac 63            LHLD     $63ac
$22cc:  cd ea 27            CALL     $27ea
$22cf:  da d3 22            JC       $22d3
$22d2:  eb                  XCHG

F_M_22d3:
$22d3:  22 c1 63            SHLD     $63c1
$22d6:  3a f0 63            LDA      $63f0
$22d9:  e6 01               ANI      $01
$22db:  ca e5 22            JZ       $22e5
$22de:  eb                  XCHG
$22df:  2a ac 63            LHLD     $63ac
$22e2:  cd f0 27            CALL     $27f0

F_M_22e5:
$22e5:  11 28 00            LXI      D,$0028
$22e8:  19                  DAD      D
$22e9:  22 bd 63            SHLD     $63bd
$22ec:  2a bf 63            LHLD     $63bf
$22ef:  7c                  MOV      A,H
$22f0:  a7                  ANA      A
$22f1:  f2 fa 22            JP       $22fa
$22f4:  21 00 00            LXI      H,$0000
$22f7:  c3 05 23            JMP      $2305

F_M_22fa:
$22fa:  eb                  XCHG
$22fb:  2a ae 63            LHLD     $63ae
$22fe:  cd ea 27            CALL     $27ea
$2301:  da 05 23            JC       $2305
$2304:  eb                  XCHG

F_M_2305:
$2305:  22 c3 63            SHLD     $63c3
$2308:  11 28 00            LXI      D,$0028
$230b:  19                  DAD      D
$230c:  3a f0 63            LDA      $63f0
$230f:  e6 01               ANI      $01
$2311:  ca 22 23            JZ       $2322
$2314:  eb                  XCHG
$2315:  2a bd 63            LHLD     $63bd
$2318:  22 bf 63            SHLD     $63bf
$231b:  eb                  XCHG
$231c:  22 bd 63            SHLD     $63bd
$231f:  c3 25 23            JMP      $2325

F_M_2322:
$2322:  22 bf 63            SHLD     $63bf

F_M_2325:
$2325:  2a bd 63            LHLD     $63bd
$2328:  11 c6 fe            LXI      D,$fec6
$232b:  cd 57 29            CALL     $2957
$232e:  eb                  XCHG
$232f:  22 bd 63            SHLD     $63bd
$2332:  2a bf 63            LHLD     $63bf
$2335:  11 c6 fe            LXI      D,$fec6
$2338:  cd 57 29            CALL     $2957
$233b:  eb                  XCHG
$233c:  22 bf 63            SHLD     $63bf
$233f:  2a 9b 63            LHLD     $639b
$2342:  eb                  XCHG
$2343:  2a bd 63            LHLD     $63bd
$2346:  22 9b 63            SHLD     $639b
$2349:  cd ea 27            CALL     $27ea
$234c:  c2 97 23            JNZ      $2397
$234f:  06 07               MVI      B,$07
$2351:  2a 9d 63            LHLD     $639d
$2354:  eb                  XCHG
$2355:  2a bf 63            LHLD     $63bf
$2358:  22 9d 63            SHLD     $639d
$235b:  cd ea 27            CALL     $27ea
$235e:  ca 71 23            JZ       $2371
$2361:  d2 67 23            JNC      $2367
$2364:  eb                  XCHG
$2365:  06 47               MVI      B,$47

F_M_2367:
$2367:  cd f0 27            CALL     $27f0

F_M_236a:
$236a:  78                  MOV      A,B

F_M_236b:
$236b:  22 ba 63            SHLD     $63ba
$236e:  c3 62 24            JMP      $2462

F_M_2371:
$2371:  3a 2f 63            LDA      $632f
$2374:  a7                  ANA      A
$2375:  3a f0 63            LDA      $63f0
$2378:  47                  MOV      B,A
$2379:  ca 89 23            JZ       $2389
$237c:  e6 02               ANI      $02
$237e:  c0                  RNZ
$237f:  3e 02               MVI      A,$02
$2381:  b0                  ORA      B
$2382:  32 f0 63            STA      $63f0
$2385:  cd 16 22            CALL     $2216
$2388:  c9                  RET

F_M_2389:
$2389:  78                  MOV      A,B
$238a:  e6 02               ANI      $02
$238c:  c8                  RZ
$238d:  3e fd               MVI      A,$fd
$238f:  a0                  ANA      B
$2390:  32 f0 63            STA      $63f0
$2393:  cd 3c 22            CALL     $223c
$2396:  c9                  RET

F_M_2397:
$2397:  06 03               MVI      B,$03
$2399:  d2 9f 23            JNC      $239f
$239c:  06 23               MVI      B,$23
$239e:  eb                  XCHG

F_M_239f:
$239f:  cd f0 27            CALL     $27f0
$23a2:  22 3c 63            SHLD     $633c
$23a5:  2a 9d 63            LHLD     $639d
$23a8:  eb                  XCHG
$23a9:  2a bf 63            LHLD     $63bf
$23ac:  22 9d 63            SHLD     $639d
$23af:  cd ea 27            CALL     $27ea
$23b2:  ca bb 23            JZ       $23bb
$23b5:  da c4 23            JC       $23c4
$23b8:  c3 c9 23            JMP      $23c9

F_M_23bb:
$23bb:  3e 08               MVI      A,$08
$23bd:  b0                  ORA      B
$23be:  2a 3c 63            LHLD     $633c
$23c1:  c3 6b 23            JMP      $236b

F_M_23c4:
$23c4:  3e 40               MVI      A,$40
$23c6:  eb                  XCHG
$23c7:  b0                  ORA      B
$23c8:  47                  MOV      B,A

F_M_23c9:
$23c9:  cd f0 27            CALL     $27f0
$23cc:  22 3e 63            SHLD     $633e
$23cf:  eb                  XCHG
$23d0:  2a 3c 63            LHLD     $633c
$23d3:  cd ea 27            CALL     $27ea
$23d6:  ca 6a 23            JZ       $236a
$23d9:  3e fd               MVI      A,$fd
$23db:  d2 e1 23            JNC      $23e1
$23de:  3e fe               MVI      A,$fe
$23e0:  eb                  XCHG

F_M_23e1:
$23e1:  a0                  ANA      B
$23e2:  32 b2 63            STA      $63b2
$23e5:  22 ba 63            SHLD     $63ba
$23e8:  eb                  XCHG
$23e9:  22 7a 61            SHLD     $617a
$23ec:  22 6e 61            SHLD     $616e
$23ef:  eb                  XCHG
$23f0:  11 00 00            LXI      D,$0000
$23f3:  cd 1e 25            CALL     $251e
$23f6:  06 0e               MVI      B,$0e

F_M_23f8:
$23f8:  cd 16 25            CALL     $2516
$23fb:  05                  DCR      B
$23fc:  c2 f8 23            JNZ      $23f8
$23ff:  22 66 61            SHLD     $6166
$2402:  eb                  XCHG
$2403:  22 68 61            SHLD     $6168
$2406:  21 00 00            LXI      H,$0000
$2409:  22 70 61            SHLD     $6170
$240c:  21 6e 61            LXI      H,$616e
$240f:  11 66 61            LXI      D,$6166
$2412:  cd 12 2a            CALL     $2a12
$2415:  cd 16 25            CALL     $2516
$2418:  da 21 24            JC       $2421
$241b:  cd 16 25            CALL     $2516
$241e:  d2 27 24            JNC      $2427

F_M_2421:
$2421:  11 fe ff            LXI      D,$fffe
$2424:  21 00 00            LXI      H,$0000

F_M_2427:
$2427:  eb                  XCHG
$2428:  d5                  PUSH     D
$2429:  11 0d 00            LXI      D,$000d
$242c:  cd ea 27            CALL     $27ea
$242f:  d1                  POP      D
$2430:  d2 42 24            JNC      $2442
$2433:  3a 58 62            LDA      $6258
$2436:  e6 1f               ANI      $1f
$2438:  fe 06               CPI      $06
$243a:  da 42 24            JC       $2442
$243d:  3e c6               MVI      A,$c6
$243f:  32 58 62            STA      $6258

F_M_2442:
$2442:  22 b8 63            SHLD     $63b8
$2445:  eb                  XCHG
$2446:  11 00 00            LXI      D,$0000
$2449:  cd 1e 25            CALL     $251e
$244c:  cd 1e 25            CALL     $251e
$244f:  7b                  MOV      A,E
$2450:  a7                  ANA      A
$2451:  3a b2 63            LDA      $63b2
$2454:  ca 62 24            JZ       $2462
$2457:  3e 63               MVI      A,$63
$2459:  93                  SUB      E
$245a:  32 b7 63            STA      $63b7
$245d:  3a b2 63            LDA      $63b2
$2460:  f6 10               ORI      $10

F_M_2462:
$2462:  32 b2 63            STA      $63b2
$2465:  32 bc 63            STA      $63bc
$2468:  3a 58 62            LDA      $6258
$246b:  47                  MOV      B,A
$246c:  07                  RLC
$246d:  07                  RLC
$246e:  07                  RLC
$246f:  32 02 e4            STA      $e402
$2472:  78                  MOV      A,B
$2473:  fe 76               CPI      $76
$2475:  ca 9b 24            JZ       $249b
$2478:  e6 1f               ANI      $1f
$247a:  21 4f 25            LXI      H,$254f
$247d:  16 00               MVI      D,$00
$247f:  5f                  MOV      E,A
$2480:  19                  DAD      D
$2481:  5e                  MOV      E,M
$2482:  fe 06               CPI      $06
$2484:  d2 91 24            JNC      $2491
$2487:  d6 04               SUI      $04
$2489:  d2 a4 24            JNC      $24a4
$248c:  3e 00               MVI      A,$00
$248e:  c3 a4 24            JMP      $24a4

F_M_2491:
$2491:  fe 0a               CPI      $0a
$2493:  d2 a2 24            JNC      $24a2
$2496:  d6 06               SUI      $06
$2498:  c3 a4 24            JMP      $24a4

F_M_249b:
$249b:  1e c5               MVI      E,$c5
$249d:  16 9f               MVI      D,$9f
$249f:  c3 ac 24            JMP      $24ac

F_M_24a2:
$24a2:  3e 05               MVI      A,$05

F_M_24a4:
$24a4:  21 4f 25            LXI      H,$254f
$24a7:  06 00               MVI      B,$00
$24a9:  4f                  MOV      C,A
$24aa:  09                  DAD      B
$24ab:  56                  MOV      D,M

F_M_24ac:
$24ac:  3e ff               MVI      A,$ff
$24ae:  92                  SUB      D
$24af:  32 b3 63            STA      $63b3
$24b2:  7b                  MOV      A,E
$24b3:  92                  SUB      D
$24b4:  32 b4 63            STA      $63b4
$24b7:  26 00               MVI      H,$00
$24b9:  6f                  MOV      L,A
$24ba:  29                  DAD      H
$24bb:  29                  DAD      H
$24bc:  29                  DAD      H
$24bd:  22 b5 63            SHLD     $63b5
$24c0:  eb                  XCHG
$24c1:  2a ba 63            LHLD     $63ba
$24c4:  cd ea 27            CALL     $27ea
$24c7:  d2 d9 24            JNC      $24d9
$24ca:  3e ff               MVI      A,$ff
$24cc:  32 b3 63            STA      $63b3
$24cf:  af                  XRA      A
$24d0:  32 b4 63            STA      $63b4
$24d3:  21 00 00            LXI      H,$0000
$24d6:  22 b5 63            SHLD     $63b5

F_M_24d9:
$24d9:  cd 71 23            CALL     $2371
$24dc:  21 03 e8            LXI      H,$e803
$24df:  36 b8               MVI      M,$b8
$24e1:  2b                  DCX      H
$24e2:  36 ff               MVI      M,$ff
$24e4:  36 ff               MVI      M,$ff
$24e6:  21 b2 63            LXI      H,$63b2
$24e9:  06 0a               MVI      B,$0a
$24eb:  7e                  MOV      A,M
$24ec:  32 00 80            STA      $8000
$24ef:  23                  INX      H
$24f0:  e5                  PUSH     H
$24f1:  2a 49 61            LHLD     $6149

F_M_24f4:
$24f4:  11 ff ff            LXI      D,$ffff
$24f7:  19                  DAD      D
$24f8:  da f4 24            JC       $24f4
$24fb:  e1                  POP      H

F_M_24fc:
$24fc:  7e                  MOV      A,M
$24fd:  32 00 80            STA      $8000
$2500:  23                  INX      H
$2501:  05                  DCR      B
$2502:  c2 fc 24            JNZ      $24fc
$2505:  06 ff               MVI      B,$ff

F_M_2507:
$2507:  05                  DCR      B
$2508:  3e 01               MVI      A,$01
$250a:  ca 29 02            JZ       $0229
$250d:  3a 00 e0            LDA      $e000
$2510:  e6 40               ANI      $40
$2512:  c2 07 25            JNZ      $2507
$2515:  c9                  RET

F_M_2516:
$2516:  29                  DAD      H
$2517:  7b                  MOV      A,E
$2518:  8b                  ADC      E
$2519:  5f                  MOV      E,A
$251a:  7a                  MOV      A,D
$251b:  8a                  ADC      D
$251c:  57                  MOV      D,A
$251d:  c9                  RET

F_M_251e:
$251e:  29                  DAD      H
$251f:  7b                  MOV      A,E
$2520:  8b                  ADC      E
$2521:  5f                  MOV      E,A
$2522:  7a                  MOV      A,D
$2523:  8a                  ADC      D
$2524:  57                  MOV      D,A
$2525:  da 48 25            JC       $2548
$2528:  d5                  PUSH     D
$2529:  e5                  PUSH     H
$252a:  29                  DAD      H
$252b:  7b                  MOV      A,E
$252c:  8b                  ADC      E
$252d:  5f                  MOV      E,A
$252e:  7a                  MOV      A,D
$252f:  8a                  ADC      D
$2530:  57                  MOV      D,A
$2531:  da 48 25            JC       $2548
$2534:  29                  DAD      H
$2535:  7b                  MOV      A,E
$2536:  8b                  ADC      E
$2537:  5f                  MOV      E,A
$2538:  7a                  MOV      A,D
$2539:  8a                  ADC      D
$253a:  57                  MOV      D,A
$253b:  da 48 25            JC       $2548
$253e:  c1                  POP      B
$253f:  09                  DAD      B
$2540:  c1                  POP      B
$2541:  7b                  MOV      A,E
$2542:  89                  ADC      C
$2543:  5f                  MOV      E,A
$2544:  7a                  MOV      A,D
$2545:  88                  ADC      B
$2546:  57                  MOV      D,A
$2547:  d0                  RNC

F_M_2548:
$2548:  21 ff ff            LXI      H,$ffff
$254b:  11 fd ff            LXI      D,$fffd
$254e:  c9                  RET
$254f:  00                  NOP
$2550:  18                  NOP
$2551:  2f                  CMA
$2552:  42                  MOV      B,D
$2553:  53                  MOV      D,E
$2554:  60                  MOV      H,B
$2555:  6d                  NOP
$2556:  79                  MOV      A,C
$2557:  82                  ADD      D
$2558:  8b                  ADC      E
$2559:  93                  SUB      E
$255a:  9a                  SBB      D
$255b:  a1                  ANA      C
$255c:  a7                  ANA      A
$255d:  ac                  XRA      H
$255e:  b1                  ORA      C
$255f:  b6                  ORA      M
$2560:  ba                  CMP      D
$2561:  be                  CMP      M
$2562:  c2 c5 c8            JNZ      $c8c5
$2565:  cc ce d1            CZ       $d1ce
$2568:  d4 d6 d8            CNC      $d8d6
$256b:  da dc de            JC       $dedc
$256e:  2a 80 61            LHLD     $6180
$2571:  cd 5e 27            CALL     $275e
$2574:  0e 2e               MVI      C,$2e
$2576:  cd ff 0a            CALL     $0aff
$2579:  2a 82 61            LHLD     $6182
$257c:  11 10 27            LXI      D,$2710
$257f:  cd 57 29            CALL     $2957
$2582:  eb                  XCHG
$2583:  cd 2c 27            CALL     $272c
$2586:  c9                  RET

F_M_2587:
$2587:  cd 44 61            CALL     $6144

F_M_258a:
$258a:  3a ac 61            LDA      $61ac
$258d:  a7                  ANA      A
$258e:  ca 4b 26            JZ       $264b
$2591:  79                  MOV      A,C
$2592:  32 ad 61            STA      $61ad
$2595:  cd f4 25            CALL     $25f4
$2598:  22 80 61            SHLD     $6180
$259b:  eb                  XCHG
$259c:  22 82 61            SHLD     $6182
$259f:  11 80 61            LXI      D,$6180
$25a2:  3a ad 61            LDA      $61ad
$25a5:  a7                  ANA      A
$25a6:  ca cd 25            JZ       $25cd
$25a9:  21 b2 61            LXI      H,$61b2
$25ac:  cd 41 2b            CALL     $2b41
$25af:  21 ba 61            LXI      H,$61ba
$25b2:  11 80 61            LXI      D,$6180
$25b5:  cd 91 2a            CALL     $2a91
$25b8:  3a ab 61            LDA      $61ab
$25bb:  a7                  ANA      A
$25bc:  2a 7d 63            LHLD     $637d
$25bf:  f2 c9 25            JP       $25c9
$25c2:  2a 81 63            LHLD     $6381
$25c5:  cd a6 28            CALL     $28a6
$25c8:  c9                  RET

F_M_25c9:
$25c9:  cd ad 28            CALL     $28ad
$25cc:  c9                  RET

F_M_25cd:
$25cd:  21 ae 61            LXI      H,$61ae
$25d0:  cd 41 2b            CALL     $2b41
$25d3:  21 b6 61            LXI      H,$61b6
$25d6:  11 80 61            LXI      D,$6180
$25d9:  cd 91 2a            CALL     $2a91
$25dc:  3a ab 61            LDA      $61ab
$25df:  1f                  RAR
$25e0:  2a 7b 63            LHLD     $637b
$25e3:  d2 c9 25            JNC      $25c9
$25e6:  2a 7f 63            LHLD     $637f
$25e9:  cd a6 28            CALL     $28a6
$25ec:  c9                  RET
$25ed:  cd ad 28            CALL     $28ad
$25f0:  c9                  RET

F_M_25f1:
$25f1:  cd 44 61            CALL     $6144

F_M_25f4:
$25f4:  cd 4b 26            CALL     $264b
$25f7:  22 80 61            SHLD     $6180
$25fa:  fe 2e               CPI      $2e
$25fc:  11 00 00            LXI      D,$0000
$25ff:  c2 40 26            JNZ      $2640
$2602:  06 05               MVI      B,$05
$2604:  21 00 00            LXI      H,$0000
$2607:  af                  XRA      A
$2608:  32 ed 63            STA      $63ed
$260b:  cd 74 26            CALL     $2674
$260e:  11 00 00            LXI      D,$0000
$2611:  7d                  MOV      A,L
$2612:  b4                  ORA      H
$2613:  ca 3d 26            JZ       $263d
$2616:  3e 04               MVI      A,$04
$2618:  90                  SUB      B
$2619:  ca 3d 26            JZ       $263d
$261c:  3d                  DCR      A
$261d:  11 0a 00            LXI      D,$000a
$2620:  ca 34 26            JZ       $2634
$2623:  11 64 00            LXI      D,$0064
$2626:  3d                  DCR      A
$2627:  ca 34 26            JZ       $2634
$262a:  3d                  DCR      A
$262b:  11 e8 03            LXI      D,$03e8
$262e:  ca 34 26            JZ       $2634
$2631:  11 10 27            LXI      D,$2710

F_M_2634:
$2634:  cd 27 29            CALL     $2927
$2637:  29                  DAD      H
$2638:  d2 3c 26            JNC      $263c
$263b:  13                  INX      D

F_M_263c:
$263c:  13                  INX      D

F_M_263d:
$263d:  2a 80 61            LHLD     $6180

F_M_2640:
$2640:  eb                  XCHG
$2641:  22 82 61            SHLD     $6182
$2644:  3a 48 61            LDA      $6148
$2647:  c9                  RET

F_M_2648:
$2648:  cd 44 61            CALL     $6144

F_M_264b:
$264b:  06 07               MVI      B,$07
$264d:  af                  XRA      A
$264e:  21 00 00            LXI      H,$0000
$2651:  32 ed 63            STA      $63ed
$2654:  3a 48 61            LDA      $6148
$2657:  c3 5d 26            JMP      $265d

F_M_265a:
$265a:  cd 44 61            CALL     $6144

F_M_265d:
$265d:  fe 20               CPI      $20
$265f:  ca 5a 26            JZ       $265a
$2662:  fe 2d               CPI      $2d
$2664:  c2 6f 26            JNZ      $266f
$2667:  3e ff               MVI      A,$ff
$2669:  32 ed 63            STA      $63ed
$266c:  c3 74 26            JMP      $2674

F_M_266f:
$266f:  fe 2b               CPI      $2b
$2671:  c2 78 26            JNZ      $2678

F_M_2674:
$2674:  cd 44 61            CALL     $6144
$2677:  05                  DCR      B

F_M_2678:
$2678:  d6 30               SUI      $30
$267a:  da a3 26            JC       $26a3
$267d:  fe 0a               CPI      $0a
$267f:  d2 a3 26            JNC      $26a3
$2682:  4f                  MOV      C,A
$2683:  29                  DAD      H
$2684:  da bb 26            JC       $26bb
$2687:  5d                  MOV      E,L
$2688:  54                  MOV      D,H
$2689:  29                  DAD      H
$268a:  da bb 26            JC       $26bb
$268d:  29                  DAD      H
$268e:  da bb 26            JC       $26bb
$2691:  19                  DAD      D
$2692:  da bb 26            JC       $26bb
$2695:  59                  MOV      E,C
$2696:  16 00               MVI      D,$00
$2698:  19                  DAD      D
$2699:  da bb 26            JC       $26bb

F_M_269c:
$269c:  cd 44 61            CALL     $6144
$269f:  05                  DCR      B
$26a0:  c2 78 26            JNZ      $2678

F_M_26a3:
$26a3:  7c                  MOV      A,H
$26a4:  a7                  ANA      A
$26a5:  f2 ab 26            JP       $26ab
$26a8:  21 ff 7f            LXI      H,$7fff

F_M_26ab:
$26ab:  3a ed 63            LDA      $63ed
$26ae:  a7                  ANA      A
$26af:  f2 b6 26            JP       $26b6
$26b2:  3e 80               MVI      A,$80
$26b4:  b4                  ORA      H
$26b5:  67                  MOV      H,A

F_M_26b6:
$26b6:  b7                  ORA      A
$26b7:  3a 48 61            LDA      $6148
$26ba:  c9                  RET

F_M_26bb:
$26bb:  21 ff 7f            LXI      H,$7fff
$26be:  c3 9c 26            JMP      $269c

F_M_26c1:
$26c1:  16 10               MVI      D,$10
$26c3:  1e 00               MVI      E,$00
$26c5:  43                  MOV      B,E
$26c6:  4b                  MOV      C,E

F_M_26c7:
$26c7:  79                  MOV      A,C
$26c8:  87                  ADD      A
$26c9:  27                  DAA
$26ca:  4f                  MOV      C,A
$26cb:  78                  MOV      A,B
$26cc:  8f                  ADC      A
$26cd:  27                  DAA
$26ce:  47                  MOV      B,A
$26cf:  7b                  MOV      A,E
$26d0:  8f                  ADC      A
$26d1:  27                  DAA
$26d2:  5f                  MOV      E,A
$26d3:  29                  DAD      H
$26d4:  d2 ea 26            JNC      $26ea
$26d7:  0c                  INR      C
$26d8:  3f                  CMC
$26d9:  79                  MOV      A,C
$26da:  27                  DAA
$26db:  4f                  MOV      C,A
$26dc:  d2 ea 26            JNC      $26ea
$26df:  04                  INR      B
$26e0:  78                  MOV      A,B
$26e1:  27                  DAA
$26e2:  47                  MOV      B,A
$26e3:  d2 ea 26            JNC      $26ea
$26e6:  1c                  INR      E
$26e7:  7b                  MOV      A,E
$26e8:  27                  DAA
$26e9:  5f                  MOV      E,A

F_M_26ea:
$26ea:  15                  DCR      D
$26eb:  c2 c7 26            JNZ      $26c7
$26ee:  7b                  MOV      A,E
$26ef:  0f                  RRC
$26f0:  0f                  RRC
$26f1:  0f                  RRC
$26f2:  0f                  RRC
$26f3:  e6 0f               ANI      $0f
$26f5:  c6 30               ADI      $30
$26f7:  32 e7 63            STA      $63e7
$26fa:  7b                  MOV      A,E
$26fb:  e6 0f               ANI      $0f
$26fd:  c6 30               ADI      $30
$26ff:  32 e8 63            STA      $63e8
$2702:  78                  MOV      A,B
$2703:  0f                  RRC
$2704:  0f                  RRC
$2705:  0f                  RRC
$2706:  0f                  RRC
$2707:  e6 0f               ANI      $0f
$2709:  c6 30               ADI      $30
$270b:  32 e9 63            STA      $63e9
$270e:  78                  MOV      A,B
$270f:  e6 0f               ANI      $0f
$2711:  c6 30               ADI      $30
$2713:  32 ea 63            STA      $63ea
$2716:  79                  MOV      A,C
$2717:  0f                  RRC
$2718:  0f                  RRC
$2719:  0f                  RRC
$271a:  0f                  RRC
$271b:  e6 0f               ANI      $0f
$271d:  c6 30               ADI      $30
$271f:  32 eb 63            STA      $63eb
$2722:  79                  MOV      A,C
$2723:  e6 0f               ANI      $0f
$2725:  c6 30               ADI      $30
$2727:  32 ec 63            STA      $63ec
$272a:  b7                  ORA      A
$272b:  c9                  RET

F_M_272c:
$272c:  cd c1 26            CALL     $26c1
$272f:  3a e9 63            LDA      $63e9
$2732:  4f                  MOV      C,A
$2733:  cd ff 0a            CALL     $0aff
$2736:  3a ea 63            LDA      $63ea
$2739:  4f                  MOV      C,A
$273a:  cd ff 0a            CALL     $0aff
$273d:  3a eb 63            LDA      $63eb
$2740:  4f                  MOV      C,A
$2741:  cd ff 0a            CALL     $0aff
$2744:  3a ec 63            LDA      $63ec
$2747:  4f                  MOV      C,A
$2748:  cd ff 0a            CALL     $0aff
$274b:  c9                  RET

F_M_274c:
$274c:  cd 5e 27            CALL     $275e
$274f:  3e 2c               MVI      A,$2c
$2751:  cd bd 27            CALL     $27bd
$2754:  c9                  RET

F_M_2755:
$2755:  cd 5e 27            CALL     $275e
$2758:  3e 3b               MVI      A,$3b
$275a:  cd bd 27            CALL     $27bd
$275d:  c9                  RET

F_M_275e:
$275e:  3e 80               MVI      A,$80
$2760:  a4                  ANA      H
$2761:  ca 69 27            JZ       $2769
$2764:  0e 2d               MVI      C,$2d
$2766:  cd ff 0a            CALL     $0aff

F_M_2769:
$2769:  7c                  MOV      A,H
$276a:  e6 7f               ANI      $7f
$276c:  67                  MOV      H,A
$276d:  cd c1 26            CALL     $26c1
$2770:  3a e7 63            LDA      $63e7
$2773:  fe 30               CPI      $30
$2775:  c2 9f 27            JNZ      $279f
$2778:  3a e8 63            LDA      $63e8
$277b:  fe 30               CPI      $30
$277d:  c2 a5 27            JNZ      $27a5
$2780:  3a e9 63            LDA      $63e9
$2783:  fe 30               CPI      $30
$2785:  c2 ab 27            JNZ      $27ab
$2788:  3a ea 63            LDA      $63ea
$278b:  fe 30               CPI      $30
$278d:  c2 b1 27            JNZ      $27b1
$2790:  3a eb 63            LDA      $63eb
$2793:  fe 30               CPI      $30
$2795:  c2 b7 27            JNZ      $27b7

F_M_2798:
$2798:  3a ec 63            LDA      $63ec
$279b:  cd bd 27            CALL     $27bd
$279e:  c9                  RET

F_M_279f:
$279f:  cd bd 27            CALL     $27bd
$27a2:  3a e8 63            LDA      $63e8

F_M_27a5:
$27a5:  cd bd 27            CALL     $27bd
$27a8:  3a e9 63            LDA      $63e9

F_M_27ab:
$27ab:  cd bd 27            CALL     $27bd
$27ae:  3a ea 63            LDA      $63ea

F_M_27b1:
$27b1:  cd bd 27            CALL     $27bd
$27b4:  3a eb 63            LDA      $63eb

F_M_27b7:
$27b7:  cd bd 27            CALL     $27bd
$27ba:  c3 98 27            JMP      $2798

F_M_27bd:
$27bd:  4f                  MOV      C,A
$27be:  cd ff 0a            CALL     $0aff
$27c1:  c9                  RET
$27c2:  7c                  MOV      A,H
$27c3:  aa                  XRA      D
$27c4:  f2 cc 27            JP       $27cc
$27c7:  aa                  XRA      D
$27c8:  f6 0f               ORI      $0f
$27ca:  07                  RLC
$27cb:  c9                  RET

F_M_27cc:
$27cc:  d5                  PUSH     D
$27cd:  e5                  PUSH     H
$27ce:  7c                  MOV      A,H
$27cf:  a7                  ANA      A
$27d0:  f2 d4 27            JP       $27d4
$27d3:  eb                  XCHG

F_M_27d4:
$27d4:  7c                  MOV      A,H
$27d5:  e6 7f               ANI      $7f
$27d7:  67                  MOV      H,A
$27d8:  7a                  MOV      A,D
$27d9:  e6 7f               ANI      $7f
$27db:  57                  MOV      D,A
$27dc:  cd ea 27            CALL     $27ea
$27df:  e1                  POP      H
$27e0:  d1                  POP      D
$27e1:  c9                  RET

F_M_27e2:
$27e2:  7a                  MOV      A,D
$27e3:  e6 7f               ANI      $7f
$27e5:  57                  MOV      D,A
$27e6:  7c                  MOV      A,H
$27e7:  e6 7f               ANI      $7f
$27e9:  67                  MOV      H,A

F_M_27ea:
$27ea:  7c                  MOV      A,H
$27eb:  ba                  CMP      D
$27ec:  c0                  RNZ
$27ed:  7d                  MOV      A,L
$27ee:  bb                  CMP      E
$27ef:  c9                  RET

F_M_27f0:
$27f0:  7d                  MOV      A,L
$27f1:  93                  SUB      E
$27f2:  6f                  MOV      L,A
$27f3:  7c                  MOV      A,H
$27f4:  9a                  SBB      D
$27f5:  67                  MOV      H,A
$27f6:  c9                  RET
$27f7:  7d                  MOV      A,L
$27f8:  9b                  SBB      E
$27f9:  6f                  MOV      L,A
$27fa:  7c                  MOV      A,H
$27fb:  9a                  SBB      D
$27fc:  67                  MOV      H,A
$27fd:  c9                  RET
$27fe:  d6 30               SUI      $30
$2800:  d8                  RC
$2801:  fe 0a               CPI      $0a
$2803:  da 0d 28            JC       $280d
$2806:  d6 07               SUI      $07
$2808:  fe 0a               CPI      $0a
$280a:  d8                  RC
$280b:  fe 10               CPI      $10

F_M_280d:
$280d:  3f                  CMC
$280e:  c9                  RET
$280f:  e6 0f               ANI      $0f
$2811:  5f                  MOV      E,A
$2812:  d6 0a               SUI      $0a
$2814:  f2 1d 28            JP       $281d
$2817:  7b                  MOV      A,E
$2818:  c6 30               ADI      $30
$281a:  c3 20 28            JMP      $2820

F_M_281d:
$281d:  7b                  MOV      A,E
$281e:  c6 37               ADI      $37

F_M_2820:
$2820:  c9                  RET

F_M_2821:
$2821:  79                  MOV      A,C
$2822:  1f                  RAR
$2823:  da 31 28            JC       $2831
$2826:  4c                  MOV      C,H
$2827:  c5                  PUSH     B
$2828:  7c                  MOV      A,H
$2829:  e6 7f               ANI      $7f
$282b:  67                  MOV      H,A
$282c:  cd 57 29            CALL     $2957
$282f:  eb                  XCHG
$2830:  c1                  POP      B

F_M_2831:
$2831:  78                  MOV      A,B
$2832:  a9                  XRA      C
$2833:  e6 80               ANI      $80
$2835:  b4                  ORA      H
$2836:  67                  MOV      H,A
$2837:  c9                  RET

F_M_2838:
$2838:  7a                  MOV      A,D
$2839:  a8                  XRA      B
$283a:  f5                  PUSH     PSW
$283b:  7a                  MOV      A,D
$283c:  e6 7f               ANI      $7f
$283e:  57                  MOV      D,A
$283f:  78                  MOV      A,B
$2840:  e6 7f               ANI      $7f
$2842:  47                  MOV      B,A
$2843:  cd 78 28            CALL     $2878
$2846:  f1                  POP      PSW
$2847:  e6 80               ANI      $80
$2849:  b2                  ORA      D
$284a:  57                  MOV      D,A
$284b:  c9                  RET
$284c:  7a                  MOV      A,D
$284d:  ac                  XRA      H
$284e:  f5                  PUSH     PSW
$284f:  7a                  MOV      A,D
$2850:  e6 7f               ANI      $7f
$2852:  57                  MOV      D,A
$2853:  7c                  MOV      A,H
$2854:  e6 7f               ANI      $7f
$2856:  67                  MOV      H,A
$2857:  cd 57 29            CALL     $2957
$285a:  f1                  POP      PSW
$285b:  e6 80               ANI      $80
$285d:  b2                  ORA      D
$285e:  57                  MOV      D,A
$285f:  c9                  RET

F_M_2860:
$2860:  7a                  MOV      A,D
$2861:  ac                  XRA      H
$2862:  f5                  PUSH     PSW
$2863:  7a                  MOV      A,D
$2864:  e6 7f               ANI      $7f
$2866:  57                  MOV      D,A
$2867:  7c                  MOV      A,H
$2868:  e6 7f               ANI      $7f
$286a:  67                  MOV      H,A
$286b:  cd e3 28            CALL     $28e3
$286e:  7a                  MOV      A,D
$286f:  e6 7f               ANI      $7f
$2871:  57                  MOV      D,A
$2872:  f1                  POP      PSW
$2873:  e6 80               ANI      $80
$2875:  b2                  ORA      D
$2876:  57                  MOV      D,A
$2877:  c9                  RET

F_M_2878:
$2878:  e5                  PUSH     H
$2879:  c5                  PUSH     B
$287a:  60                  MOV      H,B
$287b:  69                  MOV      L,C
$287c:  cd 57 29            CALL     $2957
$287f:  22 7c 61            SHLD     $617c
$2882:  eb                  XCHG
$2883:  22 7e 61            SHLD     $617e
$2886:  e1                  POP      H
$2887:  d1                  POP      D
$2888:  cd 57 29            CALL     $2957
$288b:  e5                  PUSH     H
$288c:  2a 7c 61            LHLD     $617c
$288f:  19                  DAD      D
$2890:  e5                  PUSH     H
$2891:  2a 7e 61            LHLD     $617e
$2894:  11 00 00            LXI      D,$0000
$2897:  cd 9f 28            CALL     $289f
$289a:  44                  MOV      B,H
$289b:  4d                  MOV      C,L
$289c:  d1                  POP      D
$289d:  e1                  POP      H
$289e:  c9                  RET

F_M_289f:
$289f:  7d                  MOV      A,L
$28a0:  8b                  ADC      E
$28a1:  6f                  MOV      L,A
$28a2:  7c                  MOV      A,H
$28a3:  8a                  ADC      D
$28a4:  67                  MOV      H,A
$28a5:  c9                  RET

F_M_28a6:
$28a6:  7a                  MOV      A,D
$28a7:  ee 80               XRI      $80
$28a9:  e6 80               ANI      $80
$28ab:  b2                  ORA      D
$28ac:  57                  MOV      D,A

F_M_28ad:
$28ad:  cd b4 28            CALL     $28b4
$28b0:  cd ca 28            CALL     $28ca
$28b3:  c9                  RET

F_M_28b4:
$28b4:  cd d5 28            CALL     $28d5
$28b7:  eb                  XCHG
$28b8:  cd d5 28            CALL     $28d5

F_M_28bb:
$28bb:  44                  MOV      B,H
$28bc:  19                  DAD      D
$28bd:  1f                  RAR
$28be:  ac                  XRA      H
$28bf:  a8                  XRA      B
$28c0:  aa                  XRA      D
$28c1:  f0                  RP
$28c2:  21 ff 7f            LXI      H,$7fff
$28c5:  aa                  XRA      D
$28c6:  f8                  RM
$28c7:  23                  INX      H
$28c8:  23                  INX      H
$28c9:  c9                  RET

F_M_28ca:
$28ca:  7c                  MOV      A,H
$28cb:  a7                  ANA      A
$28cc:  f0                  RP
$28cd:  cd db 28            CALL     $28db
$28d0:  7c                  MOV      A,H
$28d1:  f6 80               ORI      $80
$28d3:  67                  MOV      H,A
$28d4:  c9                  RET

F_M_28d5:
$28d5:  7c                  MOV      A,H
$28d6:  a7                  ANA      A
$28d7:  f0                  RP
$28d8:  e6 7f               ANI      $7f
$28da:  67                  MOV      H,A

F_M_28db:
$28db:  7c                  MOV      A,H
$28dc:  2f                  CMA
$28dd:  67                  MOV      H,A
$28de:  7d                  MOV      A,L
$28df:  2f                  CMA
$28e0:  6f                  MOV      L,A
$28e1:  23                  INX      H
$28e2:  c9                  RET

F_M_28e3:
$28e3:  cd ea 27            CALL     $27ea
$28e6:  ca 18 29            JZ       $2918
$28e9:  7c                  MOV      A,H
$28ea:  b5                  ORA      L
$28eb:  ca 0a 29            JZ       $290a
$28ee:  7a                  MOV      A,D
$28ef:  b3                  ORA      E
$28f0:  ca 11 29            JZ       $2911
$28f3:  d5                  PUSH     D
$28f4:  cd 1f 29            CALL     $291f
$28f7:  eb                  XCHG
$28f8:  e3                  XTHL
$28f9:  eb                  XCHG
$28fa:  cd 27 29            CALL     $2927
$28fd:  29                  DAD      H
$28fe:  eb                  XCHG
$28ff:  d2 06 29            JNC      $2906
$2902:  11 01 00            LXI      D,$0001
$2905:  19                  DAD      D

F_M_2906:
$2906:  d1                  POP      D
$2907:  d0                  RNC
$2908:  13                  INX      D
$2909:  c9                  RET

F_M_290a:
$290a:  21 00 00            LXI      H,$0000
$290d:  11 00 00            LXI      D,$0000
$2910:  c9                  RET

F_M_2911:
$2911:  21 ff ff            LXI      H,$ffff
$2914:  11 ff 7f            LXI      D,$7fff
$2917:  c9                  RET

F_M_2918:
$2918:  11 01 00            LXI      D,$0001
$291b:  21 00 00            LXI      H,$0000
$291e:  c9                  RET

F_M_291f:
$291f:  44                  MOV      B,H
$2920:  4d                  MOV      C,L
$2921:  21 00 00            LXI      H,$0000
$2924:  c3 2a 29            JMP      $292a

F_M_2927:
$2927:  01 00 00            LXI      B,$0000

F_M_292a:
$292a:  7a                  MOV      A,D
$292b:  2f                  CMA
$292c:  57                  MOV      D,A
$292d:  7b                  MOV      A,E
$292e:  2f                  CMA
$292f:  5f                  MOV      E,A
$2930:  13                  INX      D
$2931:  3e 11               MVI      A,$11

F_M_2933:
$2933:  e5                  PUSH     H
$2934:  19                  DAD      D
$2935:  d2 39 29            JNC      $2939
$2938:  e3                  XTHL

F_M_2939:
$2939:  e1                  POP      H
$293a:  f5                  PUSH     PSW
$293b:  79                  MOV      A,C
$293c:  17                  RAL
$293d:  4f                  MOV      C,A
$293e:  78                  MOV      A,B
$293f:  17                  RAL
$2940:  47                  MOV      B,A
$2941:  7d                  MOV      A,L
$2942:  17                  RAL
$2943:  6f                  MOV      L,A
$2944:  7c                  MOV      A,H
$2945:  17                  RAL
$2946:  67                  MOV      H,A
$2947:  f1                  POP      PSW
$2948:  3d                  DCR      A
$2949:  c2 33 29            JNZ      $2933
$294c:  b7                  ORA      A
$294d:  7c                  MOV      A,H
$294e:  1f                  RAR
$294f:  57                  MOV      D,A
$2950:  7d                  MOV      A,L
$2951:  1f                  RAR
$2952:  5f                  MOV      E,A
$2953:  69                  MOV      L,C
$2954:  60                  MOV      H,B
$2955:  eb                  XCHG
$2956:  c9                  RET

F_M_2957:
$2957:  7b                  MOV      A,E
$2958:  cd 70 29            CALL     $2970
$295b:  e5                  PUSH     H
$295c:  f5                  PUSH     PSW
$295d:  7a                  MOV      A,D
$295e:  cd 72 29            CALL     $2972
$2961:  57                  MOV      D,A
$2962:  f1                  POP      PSW
$2963:  84                  ADD      H
$2964:  65                  MOV      H,L
$2965:  6b                  MOV      L,E
$2966:  5f                  MOV      E,A
$2967:  d2 6b 29            JNC      $296b
$296a:  14                  INR      D

F_M_296b:
$296b:  c1                  POP      B
$296c:  09                  DAD      B
$296d:  d0                  RNC
$296e:  13                  INX      D
$296f:  c9                  RET

F_M_2970:
$2970:  44                  MOV      B,H
$2971:  4d                  MOV      C,L

F_M_2972:
$2972:  1e 00               MVI      E,$00
$2974:  63                  MOV      H,E
$2975:  6b                  MOV      L,E
$2976:  87                  ADD      A
$2977:  d2 7c 29            JNC      $297c
$297a:  09                  DAD      B
$297b:  8b                  ADC      E

F_M_297c:
$297c:  29                  DAD      H
$297d:  8f                  ADC      A
$297e:  d2 83 29            JNC      $2983
$2981:  09                  DAD      B
$2982:  8b                  ADC      E

F_M_2983:
$2983:  29                  DAD      H
$2984:  8f                  ADC      A
$2985:  d2 8a 29            JNC      $298a
$2988:  09                  DAD      B
$2989:  8b                  ADC      E

F_M_298a:
$298a:  29                  DAD      H
$298b:  8f                  ADC      A
$298c:  d2 91 29            JNC      $2991
$298f:  09                  DAD      B
$2990:  8b                  ADC      E

F_M_2991:
$2991:  29                  DAD      H
$2992:  8f                  ADC      A
$2993:  d2 98 29            JNC      $2998
$2996:  09                  DAD      B
$2997:  8b                  ADC      E

F_M_2998:
$2998:  29                  DAD      H
$2999:  8f                  ADC      A
$299a:  d2 9f 29            JNC      $299f
$299d:  09                  DAD      B
$299e:  8b                  ADC      E

F_M_299f:
$299f:  29                  DAD      H
$29a0:  8f                  ADC      A
$29a1:  d2 a6 29            JNC      $29a6
$29a4:  09                  DAD      B
$29a5:  8b                  ADC      E

F_M_29a6:
$29a6:  29                  DAD      H
$29a7:  8f                  ADC      A
$29a8:  d0                  RNC
$29a9:  09                  DAD      B
$29aa:  8b                  ADC      E
$29ab:  c9                  RET

F_M_29ac:
$29ac:  d5                  PUSH     D
$29ad:  11 52 61            LXI      D,$6152
$29b0:  cd 11 2c            CALL     $2c11
$29b3:  e1                  POP      H
$29b4:  11 56 61            LXI      D,$6156
$29b7:  cd 11 2c            CALL     $2c11
$29ba:  3e 00               MVI      A,$00
$29bc:  d2 d3 29            JNC      $29d3
$29bf:  11 59 61            LXI      D,$6159
$29c2:  21 55 61            LXI      H,$6155
$29c5:  1a                  LDAX     D
$29c6:  4f                  MOV      C,A
$29c7:  e6 7f               ANI      $7f
$29c9:  12                  STAX     D
$29ca:  7e                  MOV      A,M
$29cb:  47                  MOV      B,A
$29cc:  e6 7f               ANI      $7f
$29ce:  77                  MOV      M,A
$29cf:  79                  MOV      A,C
$29d0:  a8                  XRA      B
$29d1:  e6 80               ANI      $80

F_M_29d3:
$29d3:  32 ee 63            STA      $63ee
$29d6:  c9                  RET
$29d7:  21 00 00            LXI      H,$0000
$29da:  5d                  MOV      E,L
$29db:  55                  MOV      D,L
$29dc:  c3 e5 29            JMP      $29e5

F_M_29df:
$29df:  21 ff ff            LXI      H,$ffff
$29e2:  11 ff 7f            LXI      D,$7fff

F_M_29e5:
$29e5:  3a ee 63            LDA      $63ee
$29e8:  a7                  ANA      A
$29e9:  c8                  RZ
$29ea:  b2                  ORA      D
$29eb:  57                  MOV      D,A
$29ec:  c9                  RET
$29ed:  a7                  ANA      A
$29ee:  c3 f2 29            JMP      $29f2

F_M_29f1:
$29f1:  37                  STC

F_M_29f2:
$29f2:  cd ac 29            CALL     $29ac
$29f5:  cd 16 2a            CALL     $2a16
$29f8:  7a                  MOV      A,D
$29f9:  b3                  ORA      E
$29fa:  c2 df 29            JNZ      $29df
$29fd:  7c                  MOV      A,H
$29fe:  a7                  ANA      A
$29ff:  fa df 29            JM       $29df
$2a02:  e5                  PUSH     H
$2a03:  21 56 61            LXI      H,$6156
$2a06:  af                  XRA      A
$2a07:  cd 20 2c            CALL     $2c20
$2a0a:  cd 43 2a            CALL     $2a43
$2a0d:  eb                  XCHG
$2a0e:  d1                  POP      D
$2a0f:  c3 e5 29            JMP      $29e5

F_M_2a12:
$2a12:  a7                  ANA      A
$2a13:  cd ac 29            CALL     $29ac

F_M_2a16:
$2a16:  21 5a 61            LXI      H,$615a
$2a19:  af                  XRA      A
$2a1a:  cd 20 2c            CALL     $2c20
$2a1d:  2a 56 61            LHLD     $6156
$2a20:  7c                  MOV      A,H
$2a21:  b5                  ORA      L
$2a22:  c2 2d 2a            JNZ      $2a2d
$2a25:  2a 58 61            LHLD     $6158
$2a28:  7c                  MOV      A,H
$2a29:  b5                  ORA      L
$2a2a:  ca 8b 2a            JZ       $2a8b

F_M_2a2d:
$2a2d:  2a 52 61            LHLD     $6152
$2a30:  7c                  MOV      A,H
$2a31:  b5                  ORA      L
$2a32:  c2 3d 2a            JNZ      $2a3d
$2a35:  2a 54 61            LHLD     $6154
$2a38:  7c                  MOV      A,H
$2a39:  b5                  ORA      L
$2a3a:  ca 84 2a            JZ       $2a84

F_M_2a3d:
$2a3d:  21 52 61            LXI      H,$6152
$2a40:  cd 8b 2b            CALL     $2b8b

F_M_2a43:
$2a43:  0e 21               MVI      C,$21

F_M_2a45:
$2a45:  21 5a 61            LXI      H,$615a
$2a48:  11 5e 61            LXI      D,$615e
$2a4b:  cd 11 2c            CALL     $2c11
$2a4e:  11 5a 61            LXI      D,$615a
$2a51:  21 52 61            LXI      H,$6152
$2a54:  a7                  ANA      A
$2a55:  cd fe 2b            CALL     $2bfe
$2a58:  da 65 2a            JC       $2a65
$2a5b:  11 5a 61            LXI      D,$615a
$2a5e:  21 5e 61            LXI      H,$615e
$2a61:  cd 11 2c            CALL     $2c11
$2a64:  a7                  ANA      A

F_M_2a65:
$2a65:  21 56 61            LXI      H,$6156
$2a68:  cd d5 2b            CALL     $2bd5
$2a6b:  21 5a 61            LXI      H,$615a
$2a6e:  cd d5 2b            CALL     $2bd5
$2a71:  0d                  DCR      C
$2a72:  c2 45 2a            JNZ      $2a45
$2a75:  a7                  ANA      A
$2a76:  21 5a 61            LXI      H,$615a
$2a79:  cd 3f 2c            CALL     $2c3f
$2a7c:  2a 58 61            LHLD     $6158
$2a7f:  eb                  XCHG
$2a80:  2a 56 61            LHLD     $6156
$2a83:  c9                  RET

F_M_2a84:
$2a84:  21 ff ff            LXI      H,$ffff
$2a87:  11 ff 7f            LXI      D,$7fff
$2a8a:  c9                  RET

F_M_2a8b:
$2a8b:  21 00 00            LXI      H,$0000
$2a8e:  55                  MOV      D,L
$2a8f:  5d                  MOV      E,L
$2a90:  c9                  RET

F_M_2a91:
$2a91:  37                  STC
$2a92:  cd ac 29            CALL     $29ac
$2a95:  2a 52 61            LHLD     $6152
$2a98:  eb                  XCHG
$2a99:  2a 56 61            LHLD     $6156
$2a9c:  cd 57 29            CALL     $2957
$2a9f:  29                  DAD      H
$2aa0:  d2 a4 2a            JNC      $2aa4
$2aa3:  13                  INX      D

F_M_2aa4:
$2aa4:  d5                  PUSH     D
$2aa5:  2a 54 61            LHLD     $6154
$2aa8:  eb                  XCHG
$2aa9:  2a 56 61            LHLD     $6156
$2aac:  cd 57 29            CALL     $2957
$2aaf:  c1                  POP      B
$2ab0:  09                  DAD      B
$2ab1:  d2 b5 2a            JNC      $2ab5
$2ab4:  13                  INX      D

F_M_2ab5:
$2ab5:  d5                  PUSH     D
$2ab6:  e5                  PUSH     H
$2ab7:  2a 52 61            LHLD     $6152
$2aba:  eb                  XCHG
$2abb:  2a 58 61            LHLD     $6158
$2abe:  cd 57 29            CALL     $2957
$2ac1:  c1                  POP      B
$2ac2:  09                  DAD      B
$2ac3:  d2 c7 2a            JNC      $2ac7
$2ac6:  13                  INX      D

F_M_2ac7:
$2ac7:  c1                  POP      B
$2ac8:  eb                  XCHG
$2ac9:  09                  DAD      B
$2aca:  da df 29            JC       $29df
$2acd:  7c                  MOV      A,H
$2ace:  a7                  ANA      A
$2acf:  fa df 29            JM       $29df
$2ad2:  e5                  PUSH     H
$2ad3:  d5                  PUSH     D
$2ad4:  2a 58 61            LHLD     $6158
$2ad7:  eb                  XCHG
$2ad8:  2a 54 61            LHLD     $6154
$2adb:  cd 57 29            CALL     $2957
$2ade:  7a                  MOV      A,D
$2adf:  b3                  ORA      E
$2ae0:  d1                  POP      D
$2ae1:  c1                  POP      B
$2ae2:  c2 df 29            JNZ      $29df
$2ae5:  09                  DAD      B
$2ae6:  da df 29            JC       $29df
$2ae9:  7c                  MOV      A,H
$2aea:  a7                  ANA      A
$2aeb:  fa df 29            JM       $29df
$2aee:  eb                  XCHG
$2aef:  c3 e5 29            JMP      $29e5
$2af2:  d5           DB  $d5
$2af3:  11           DB  $11
$2af4:  52           DB  $52
$2af5:  61           DB  $61
$2af6:  cd           DB  $cd
$2af7:  11           DB  $11
$2af8:  2c           DB  $2c
$2af9:  e1           DB  $e1
$2afa:  11           DB  $11
$2afb:  56           DB  $56
$2afc:  61           DB  $61
$2afd:  cd           DB  $cd
$2afe:  11           DB  $11
$2aff:  2c           DB  $2c
$2b00:  af           DB  $af
$2b01:  21           DB  $21
$2b02:  5a           DB  $5a
$2b03:  61           DB  $61
$2b04:  cd           DB  $cd
$2b05:  20           DB  $20
$2b06:  2c           DB  $2c
$2b07:  cd           DB  $cd
$2b08:  20           DB  $20
$2b09:  2c           DB  $2c
$2b0a:  0e           DB  $0e
$2b0b:  20           DB  $20
$2b0c:  a7           DB  $a7
$2b0d:  21           DB  $21
$2b0e:  52           DB  $52
$2b0f:  61           DB  $61
$2b10:  cd           DB  $cd
$2b11:  d5           DB  $d5
$2b12:  2b           DB  $2b
$2b13:  d2           DB  $d2
$2b14:  29           DB  $29
$2b15:  2b           DB  $2b
$2b16:  21           DB  $21
$2b17:  56           DB  $56
$2b18:  61           DB  $61
$2b19:  11           DB  $11
$2b1a:  5a           DB  $5a
$2b1b:  61           DB  $61
$2b1c:  af           DB  $af
$2b1d:  cd           DB  $cd
$2b1e:  fe           DB  $fe
$2b1f:  2b           DB  $2b
$2b20:  d2           DB  $d2
$2b21:  29           DB  $29
$2b22:  2b           DB  $2b
$2b23:  21           DB  $21
$2b24:  5e           DB  $5e
$2b25:  61           DB  $61
$2b26:  cd           DB  $cd
$2b27:  ca           DB  $ca
$2b28:  2b           DB  $2b
$2b29:  af           DB  $af
$2b2a:  21           DB  $21
$2b2b:  5a           DB  $5a
$2b2c:  61           DB  $61
$2b2d:  54           DB  $54
$2b2e:  5d           DB  $5d
$2b2f:  cd           DB  $cd
$2b30:  fe           DB  $fe
$2b31:  2b           DB  $2b
$2b32:  cd           DB  $cd
$2b33:  fe           DB  $fe
$2b34:  2b           DB  $2b
$2b35:  0d           DB  $0d
$2b36:  c2           DB  $c2
$2b37:  0d           DB  $0d
$2b38:  2b           DB  $2b
$2b39:  2a           DB  $2a
$2b3a:  5e           DB  $5e
$2b3b:  61           DB  $61
$2b3c:  eb           DB  $eb
$2b3d:  2a           DB  $2a
$2b3e:  5c           DB  $5c
$2b3f:  61           DB  $61
$2b40:  c9           DB  $c9

F_M_2b41:
$2b41:  e5                  PUSH     H
$2b42:  23                  INX      H
$2b43:  23                  INX      H
$2b44:  23                  INX      H
$2b45:  46                  MOV      B,M
$2b46:  78                  MOV      A,B
$2b47:  af                  XRA      A
$2b48:  e6 80               ANI      $80
$2b4a:  b0                  ORA      B
$2b4b:  77                  MOV      M,A
$2b4c:  e1                  POP      H
$2b4d:  eb                  XCHG
$2b4e:  e5                  PUSH     H
$2b4f:  cd 7c 2b            CALL     $2b7c
$2b52:  e1                  POP      H
$2b53:  eb                  XCHG
$2b54:  e5                  PUSH     H
$2b55:  cd 7c 2b            CALL     $2b7c
$2b58:  e1                  POP      H
$2b59:  d5                  PUSH     D
$2b5a:  cd a3 2b            CALL     $2ba3
$2b5d:  62                  MOV      H,D
$2b5e:  6b                  MOV      L,E
$2b5f:  23                  INX      H
$2b60:  23                  INX      H
$2b61:  23                  INX      H
$2b62:  7e                  MOV      A,M
$2b63:  a7                  ANA      A
$2b64:  e1                  POP      H
$2b65:  f2 72 2b            JP       $2b72
$2b68:  62                  MOV      H,D
$2b69:  6b                  MOV      L,E
$2b6a:  cd 8b 2b            CALL     $2b8b
$2b6d:  7e                  MOV      A,M
$2b6e:  f6 80               ORI      $80
$2b70:  77                  MOV      M,A
$2b71:  eb                  XCHG

F_M_2b72:
$2b72:  4e                  MOV      C,M
$2b73:  23                  INX      H
$2b74:  46                  MOV      B,M
$2b75:  23                  INX      H
$2b76:  5e                  MOV      E,M
$2b77:  23                  INX      H
$2b78:  56                  MOV      D,M
$2b79:  60                  MOV      H,B
$2b7a:  69                  MOV      L,C
$2b7b:  c9                  RET

F_M_2b7c:
$2b7c:  e5                  PUSH     H
$2b7d:  23                  INX      H
$2b7e:  23                  INX      H
$2b7f:  23                  INX      H
$2b80:  7e                  MOV      A,M
$2b81:  a7                  ANA      A
$2b82:  fa 87 2b            JM       $2b87
$2b85:  e1                  POP      H
$2b86:  c9                  RET

F_M_2b87:
$2b87:  e6 7f               ANI      $7f
$2b89:  77                  MOV      M,A
$2b8a:  e1                  POP      H

F_M_2b8b:
$2b8b:  7e                  MOV      A,M
$2b8c:  2f                  CMA
$2b8d:  c6 01               ADI      $01
$2b8f:  77                  MOV      M,A
$2b90:  23                  INX      H
$2b91:  7e                  MOV      A,M
$2b92:  2f                  CMA
$2b93:  ce 00               ACI      $00
$2b95:  77                  MOV      M,A
$2b96:  23                  INX      H
$2b97:  7e                  MOV      A,M
$2b98:  2f                  CMA
$2b99:  ce 00               ACI      $00
$2b9b:  77                  MOV      M,A
$2b9c:  23                  INX      H
$2b9d:  7e                  MOV      A,M
$2b9e:  2f                  CMA
$2b9f:  ce 00               ACI      $00
$2ba1:  77                  MOV      M,A
$2ba2:  c9                  RET

F_M_2ba3:
$2ba3:  d5                  PUSH     D
$2ba4:  13                  INX      D
$2ba5:  13                  INX      D
$2ba6:  13                  INX      D
$2ba7:  1a                  LDAX     D
$2ba8:  47                  MOV      B,A
$2ba9:  d1                  POP      D
$2baa:  d5                  PUSH     D
$2bab:  cd fe 2b            CALL     $2bfe
$2bae:  4f                  MOV      C,A
$2baf:  1f                  RAR
$2bb0:  ae                  XRA      M
$2bb1:  a8                  XRA      B
$2bb2:  a9                  XRA      C
$2bb3:  4e                  MOV      C,M
$2bb4:  d1                  POP      D
$2bb5:  f0                  RP
$2bb6:  47                  MOV      B,A
$2bb7:  62                  MOV      H,D
$2bb8:  6b                  MOV      L,E
$2bb9:  3e ff               MVI      A,$ff
$2bbb:  cd 20 2c            CALL     $2c20
$2bbe:  2b                  DCX      H
$2bbf:  36 7f               MVI      M,$7f
$2bc1:  78                  MOV      A,B
$2bc2:  a9                  XRA      C
$2bc3:  f8                  RM
$2bc4:  62                  MOV      H,D
$2bc5:  6b                  MOV      L,E
$2bc6:  cd 8b 2b            CALL     $2b8b
$2bc9:  c9                  RET
$2bca:  34                  INR      M
$2bcb:  23                  INX      H
$2bcc:  c0                  RNZ
$2bcd:  34                  INR      M
$2bce:  23                  INX      H
$2bcf:  c0                  RNZ
$2bd0:  34                  INR      M
$2bd1:  23                  INX      H
$2bd2:  c0                  RNZ
$2bd3:  34                  INR      M
$2bd4:  c9                  RET

F_M_2bd5:
$2bd5:  7e                  MOV      A,M
$2bd6:  17                  RAL
$2bd7:  77                  MOV      M,A
$2bd8:  23                  INX      H
$2bd9:  7e                  MOV      A,M
$2bda:  17                  RAL
$2bdb:  77                  MOV      M,A
$2bdc:  23                  INX      H
$2bdd:  7e                  MOV      A,M
$2bde:  17                  RAL
$2bdf:  77                  MOV      M,A
$2be0:  23                  INX      H
$2be1:  7e                  MOV      A,M
$2be2:  17                  RAL
$2be3:  77                  MOV      M,A
$2be4:  23                  INX      H
$2be5:  c9                  RET

F_M_2be6:
$2be6:  23                  INX      H
$2be7:  23                  INX      H
$2be8:  23                  INX      H
$2be9:  13                  INX      D
$2bea:  13                  INX      D
$2beb:  13                  INX      D
$2bec:  1a                  LDAX     D
$2bed:  be                  CMP      M
$2bee:  c0                  RNZ
$2bef:  2b                  DCX      H
$2bf0:  1b                  DCX      D
$2bf1:  1a                  LDAX     D
$2bf2:  be                  CMP      M
$2bf3:  c0                  RNZ
$2bf4:  2b                  DCX      H
$2bf5:  1b                  DCX      D
$2bf6:  1a                  LDAX     D
$2bf7:  be                  CMP      M
$2bf8:  c0                  RNZ
$2bf9:  2b                  DCX      H
$2bfa:  1b                  DCX      D
$2bfb:  1a                  LDAX     D
$2bfc:  be                  CMP      M
$2bfd:  c9                  RET

F_M_2bfe:
$2bfe:  1a                  LDAX     D
$2bff:  8e                  ADC      M
$2c00:  12                  STAX     D
$2c01:  23                  INX      H
$2c02:  13                  INX      D
$2c03:  1a                  LDAX     D
$2c04:  8e                  ADC      M
$2c05:  12                  STAX     D
$2c06:  23                  INX      H
$2c07:  13                  INX      D
$2c08:  1a                  LDAX     D
$2c09:  8e                  ADC      M
$2c0a:  12                  STAX     D
$2c0b:  23                  INX      H
$2c0c:  13                  INX      D
$2c0d:  1a                  LDAX     D
$2c0e:  8e                  ADC      M
$2c0f:  12                  STAX     D
$2c10:  c9                  RET

F_M_2c11:
$2c11:  7e                  MOV      A,M
$2c12:  12                  STAX     D
$2c13:  23                  INX      H
$2c14:  13                  INX      D
$2c15:  7e                  MOV      A,M
$2c16:  12                  STAX     D
$2c17:  23                  INX      H
$2c18:  13                  INX      D
$2c19:  7e                  MOV      A,M
$2c1a:  12                  STAX     D
$2c1b:  23                  INX      H
$2c1c:  13                  INX      D
$2c1d:  7e                  MOV      A,M
$2c1e:  12                  STAX     D
$2c1f:  c9                  RET

F_M_2c20:
$2c20:  06 04               MVI      B,$04

F_M_2c22:
$2c22:  77                  MOV      M,A
$2c23:  23                  INX      H
$2c24:  05                  DCR      B
$2c25:  c2 22 2c            JNZ      $2c22
$2c28:  c9                  RET

F_M_2c29:
$2c29:  a7                  ANA      A
$2c2a:  7c                  MOV      A,H
$2c2b:  1f                  RAR
$2c2c:  67                  MOV      H,A
$2c2d:  7d                  MOV      A,L
$2c2e:  1f                  RAR
$2c2f:  6f                  MOV      L,A
$2c30:  c9                  RET

F_M_2c31:
$2c31:  06 04               MVI      B,$04

F_M_2c33:
$2c33:  1a                  LDAX     D
$2c34:  4e                  MOV      C,M
$2c35:  77                  MOV      M,A
$2c36:  79                  MOV      A,C
$2c37:  12                  STAX     D
$2c38:  23                  INX      H
$2c39:  13                  INX      D
$2c3a:  05                  DCR      B
$2c3b:  c2 33 2c            JNZ      $2c33
$2c3e:  c9                  RET

F_M_2c3f:
$2c3f:  23                  INX      H
$2c40:  23                  INX      H
$2c41:  23                  INX      H
$2c42:  7e                  MOV      A,M
$2c43:  1f                  RAR
$2c44:  77                  MOV      M,A
$2c45:  2b                  DCX      H
$2c46:  7e                  MOV      A,M
$2c47:  1f                  RAR
$2c48:  77                  MOV      M,A
$2c49:  2b                  DCX      H
$2c4a:  7e                  MOV      A,M
$2c4b:  1f                  RAR
$2c4c:  77                  MOV      M,A
$2c4d:  2b                  DCX      H
$2c4e:  7e                  MOV      A,M
$2c4f:  1f                  RAR
$2c50:  77                  MOV      M,A
$2c51:  c9                  RET
$2c52:  1a                  LDAX     D
$2c53:  9e                  SBB      M
$2c54:  12                  STAX     D
$2c55:  23                  INX      H
$2c56:  13                  INX      D
$2c57:  1a                  LDAX     D
$2c58:  9e                  SBB      M
$2c59:  12                  STAX     D
$2c5a:  23                  INX      H
$2c5b:  13                  INX      D
$2c5c:  1a                  LDAX     D
$2c5d:  9e                  SBB      M
$2c5e:  12                  STAX     D
$2c5f:  23                  INX      H
$2c60:  13                  INX      D
$2c61:  1a                  LDAX     D
$2c62:  9e                  SBB      M
$2c63:  12                  STAX     D
$2c64:  c9                  RET
$2c65:  cd 7c 02            CALL     $027c
$2c68:  21 00 00            LXI      H,$0000
$2c6b:  2a 4e 63            LHLD     $634e
$2c6e:  22 3a 62            SHLD     $623a
$2c71:  22 32 62            SHLD     $6232
$2c74:  2a 50 63            LHLD     $6350
$2c77:  22 3c 62            SHLD     $623c
$2c7a:  22 34 62            SHLD     $6234
$2c7d:  2a 5d 63            LHLD     $635d
$2c80:  22 3e 62            SHLD     $623e
$2c83:  2a 5f 63            LHLD     $635f
$2c86:  22 40 62            SHLD     $6240
$2c89:  2a d6 61            LHLD     $61d6
$2c8c:  22 46 62            SHLD     $6246
$2c8f:  2a d4 61            LHLD     $61d4
$2c92:  22 42 62            SHLD     $6242
$2c95:  2a ce 61            LHLD     $61ce
$2c98:  22 44 62            SHLD     $6244

F_M_2c9b:
$2c9b:  3a 44 62            LDA      $6244
$2c9e:  e6 01               ANI      $01
$2ca0:  ca 2a 2d            JZ       $2d2a
$2ca3:  3a 44 62            LDA      $6244
$2ca6:  e6 fe               ANI      $fe
$2ca8:  32 44 62            STA      $6244
$2cab:  2a 3a 62            LHLD     $623a
$2cae:  eb                  XCHG
$2caf:  2a 3e 62            LHLD     $623e
$2cb2:  cd 09 31            CALL     $3109
$2cb5:  3e 00               MVI      A,$00
$2cb7:  d2 c5 2c            JNC      $2cc5
$2cba:  2a 42 62            LHLD     $6242
$2cbd:  cd f3 30            CALL     $30f3
$2cc0:  22 42 62            SHLD     $6242
$2cc3:  3e ff               MVI      A,$ff

F_M_2cc5:
$2cc5:  32 ef 63            STA      $63ef
$2cc8:  2a 3c 62            LHLD     $623c
$2ccb:  22 4a 62            SHLD     $624a
$2cce:  2a 3a 62            LHLD     $623a
$2cd1:  22 48 62            SHLD     $6248

F_M_2cd4:
$2cd4:  2a 42 62            LHLD     $6242
$2cd7:  eb                  XCHG
$2cd8:  2a 48 62            LHLD     $6248
$2cdb:  19                  DAD      D
$2cdc:  7c                  MOV      A,H
$2cdd:  a7                  ANA      A
$2cde:  fa e9 2e            JM       $2ee9
$2ce1:  22 48 62            SHLD     $6248
$2ce4:  eb                  XCHG
$2ce5:  2a 3e 62            LHLD     $623e
$2ce8:  3a ef 63            LDA      $63ef
$2ceb:  a7                  ANA      A
$2cec:  f2 f0 2c            JP       $2cf0
$2cef:  eb                  XCHG

F_M_2cf0:
$2cf0:  cd 09 31            CALL     $3109
$2cf3:  da e9 2e            JC       $2ee9
$2cf6:  ca e9 2e            JZ       $2ee9
$2cf9:  2a 48 62            LHLD     $6248
$2cfc:  22 5d 63            SHLD     $635d
$2cff:  2a 4a 62            LHLD     $624a
$2d02:  22 5f 63            SHLD     $635f
$2d05:  cd 0c 11            CALL     $110c
$2d08:  cd e0 1c            CALL     $1ce0
$2d0b:  2a 4a 62            LHLD     $624a
$2d0e:  eb                  XCHG
$2d0f:  2a 40 62            LHLD     $6240
$2d12:  cd 09 31            CALL     $3109
$2d15:  c2 1b 2d            JNZ      $2d1b
$2d18:  2a 3c 62            LHLD     $623c

F_M_2d1b:
$2d1b:  22 4a 62            SHLD     $624a
$2d1e:  22 5f 63            SHLD     $635f
$2d21:  cd 16 11            CALL     $1116
$2d24:  cd e0 1c            CALL     $1ce0
$2d27:  c3 d4 2c            JMP      $2cd4

F_M_2d2a:
$2d2a:  3a 44 62            LDA      $6244
$2d2d:  e6 04               ANI      $04
$2d2f:  ca bf 2d            JZ       $2dbf
$2d32:  3a 44 62            LDA      $6244
$2d35:  e6 fb               ANI      $fb
$2d37:  32 44 62            STA      $6244
$2d3a:  2a d4 61            LHLD     $61d4
$2d3d:  22 42 62            SHLD     $6242
$2d40:  2a 3c 62            LHLD     $623c
$2d43:  eb                  XCHG
$2d44:  2a 40 62            LHLD     $6240
$2d47:  cd 09 31            CALL     $3109
$2d4a:  3e 00               MVI      A,$00
$2d4c:  d2 5a 2d            JNC      $2d5a
$2d4f:  2a 42 62            LHLD     $6242
$2d52:  cd f3 30            CALL     $30f3
$2d55:  22 42 62            SHLD     $6242
$2d58:  3e ff               MVI      A,$ff

F_M_2d5a:
$2d5a:  32 ef 63            STA      $63ef
$2d5d:  2a 3a 62            LHLD     $623a
$2d60:  22 48 62            SHLD     $6248
$2d63:  2a 3c 62            LHLD     $623c
$2d66:  22 4a 62            SHLD     $624a

F_M_2d69:
$2d69:  2a 42 62            LHLD     $6242
$2d6c:  eb                  XCHG
$2d6d:  2a 4a 62            LHLD     $624a
$2d70:  19                  DAD      D
$2d71:  7c                  MOV      A,H
$2d72:  a7                  ANA      A
$2d73:  fa e9 2e            JM       $2ee9
$2d76:  22 4a 62            SHLD     $624a
$2d79:  eb                  XCHG
$2d7a:  2a 40 62            LHLD     $6240
$2d7d:  3a ef 63            LDA      $63ef
$2d80:  a7                  ANA      A
$2d81:  f2 85 2d            JP       $2d85
$2d84:  eb                  XCHG

F_M_2d85:
$2d85:  cd 09 31            CALL     $3109
$2d88:  da e9 2e            JC       $2ee9
$2d8b:  ca e9 2e            JZ       $2ee9
$2d8e:  2a 48 62            LHLD     $6248
$2d91:  22 5d 63            SHLD     $635d
$2d94:  2a 4a 62            LHLD     $624a
$2d97:  22 5f 63            SHLD     $635f
$2d9a:  cd 0c 11            CALL     $110c
$2d9d:  cd e0 1c            CALL     $1ce0
$2da0:  2a 48 62            LHLD     $6248
$2da3:  eb                  XCHG
$2da4:  2a 3e 62            LHLD     $623e
$2da7:  cd 09 31            CALL     $3109
$2daa:  c2 b0 2d            JNZ      $2db0
$2dad:  2a 3a 62            LHLD     $623a

F_M_2db0:
$2db0:  22 48 62            SHLD     $6248
$2db3:  22 5d 63            SHLD     $635d
$2db6:  cd 16 11            CALL     $1116
$2db9:  cd e0 1c            CALL     $1ce0
$2dbc:  c3 69 2d            JMP      $2d69

F_M_2dbf:
$2dbf:  3a 44 62            LDA      $6244
$2dc2:  e6 02               ANI      $02
$2dc4:  ca 54 2e            JZ       $2e54
$2dc7:  3a 44 62            LDA      $6244
$2dca:  e6 fd               ANI      $fd
$2dcc:  32 44 62            STA      $6244
$2dcf:  2a d4 61            LHLD     $61d4
$2dd2:  22 42 62            SHLD     $6242
$2dd5:  2a 3a 62            LHLD     $623a
$2dd8:  eb                  XCHG
$2dd9:  2a 3e 62            LHLD     $623e
$2ddc:  cd 09 31            CALL     $3109
$2ddf:  d2 e9 2d            JNC      $2de9
$2de2:  22 3a 62            SHLD     $623a
$2de5:  eb                  XCHG
$2de6:  22 3e 62            SHLD     $623e

F_M_2de9:
$2de9:  2a 3c 62            LHLD     $623c
$2dec:  eb                  XCHG
$2ded:  2a 40 62            LHLD     $6240
$2df0:  cd 09 31            CALL     $3109
$2df3:  da fd 2d            JC       $2dfd
$2df6:  22 3c 62            SHLD     $623c
$2df9:  eb                  XCHG
$2dfa:  22 40 62            SHLD     $6240

F_M_2dfd:
$2dfd:  11 66 66            LXI      D,$6666
$2e00:  2a 42 62            LHLD     $6242
$2e03:  cd 57 29            CALL     $2957
$2e06:  2a 42 62            LHLD     $6242
$2e09:  19                  DAD      D
$2e0a:  22 42 62            SHLD     $6242
$2e0d:  2a 3a 62            LHLD     $623a
$2e10:  22 4c 62            SHLD     $624c
$2e13:  22 50 62            SHLD     $6250
$2e16:  2a 3c 62            LHLD     $623c
$2e19:  22 4e 62            SHLD     $624e
$2e1c:  22 52 62            SHLD     $6252

F_M_2e1f:
$2e1f:  cd 5d 2f            CALL     $2f5d
$2e22:  cd 0c 11            CALL     $110c
$2e25:  3a 54 62            LDA      $6254
$2e28:  a7                  ANA      A
$2e29:  c2 e9 2e            JNZ      $2ee9
$2e2c:  cd e0 1c            CALL     $1ce0
$2e2f:  cd c2 2f            CALL     $2fc2
$2e32:  cd 16 11            CALL     $1116
$2e35:  cd e0 1c            CALL     $1ce0
$2e38:  cd c2 2f            CALL     $2fc2
$2e3b:  cd 0c 11            CALL     $110c
$2e3e:  3a 54 62            LDA      $6254
$2e41:  a7                  ANA      A
$2e42:  c2 e9 2e            JNZ      $2ee9
$2e45:  cd e0 1c            CALL     $1ce0
$2e48:  cd 5d 2f            CALL     $2f5d
$2e4b:  cd 16 11            CALL     $1116
$2e4e:  cd e0 1c            CALL     $1ce0
$2e51:  c3 1f 2e            JMP      $2e1f

F_M_2e54:
$2e54:  3a 44 62            LDA      $6244
$2e57:  e6 08               ANI      $08
$2e59:  ca e9 2e            JZ       $2ee9
$2e5c:  3a 44 62            LDA      $6244
$2e5f:  e6 f7               ANI      $f7
$2e61:  32 44 62            STA      $6244
$2e64:  2a d4 61            LHLD     $61d4
$2e67:  22 42 62            SHLD     $6242
$2e6a:  2a 3a 62            LHLD     $623a
$2e6d:  eb                  XCHG
$2e6e:  2a 3e 62            LHLD     $623e
$2e71:  cd 09 31            CALL     $3109
$2e74:  d2 7e 2e            JNC      $2e7e
$2e77:  22 3a 62            SHLD     $623a
$2e7a:  eb                  XCHG
$2e7b:  22 3e 62            SHLD     $623e

F_M_2e7e:
$2e7e:  2a 3c 62            LHLD     $623c
$2e81:  eb                  XCHG
$2e82:  2a 40 62            LHLD     $6240
$2e85:  cd 09 31            CALL     $3109
$2e88:  d2 92 2e            JNC      $2e92
$2e8b:  22 3c 62            SHLD     $623c
$2e8e:  eb                  XCHG
$2e8f:  22 40 62            SHLD     $6240

F_M_2e92:
$2e92:  11 66 66            LXI      D,$6666
$2e95:  2a 42 62            LHLD     $6242
$2e98:  cd 57 29            CALL     $2957
$2e9b:  2a 42 62            LHLD     $6242
$2e9e:  19                  DAD      D
$2e9f:  22 42 62            SHLD     $6242
$2ea2:  2a 3a 62            LHLD     $623a
$2ea5:  22 4c 62            SHLD     $624c
$2ea8:  22 50 62            SHLD     $6250
$2eab:  2a 3c 62            LHLD     $623c
$2eae:  22 4e 62            SHLD     $624e
$2eb1:  22 52 62            SHLD     $6252

F_M_2eb4:
$2eb4:  cd 2d 30            CALL     $302d
$2eb7:  cd 0c 11            CALL     $110c
$2eba:  3a 54 62            LDA      $6254
$2ebd:  a7                  ANA      A
$2ebe:  c2 e9 2e            JNZ      $2ee9
$2ec1:  cd e0 1c            CALL     $1ce0
$2ec4:  cd 8d 30            CALL     $308d
$2ec7:  cd 16 11            CALL     $1116
$2eca:  cd e0 1c            CALL     $1ce0
$2ecd:  cd 8d 30            CALL     $308d
$2ed0:  cd 0c 11            CALL     $110c
$2ed3:  3a 54 62            LDA      $6254
$2ed6:  a7                  ANA      A
$2ed7:  c2 e9 2e            JNZ      $2ee9
$2eda:  cd e0 1c            CALL     $1ce0
$2edd:  cd 2d 30            CALL     $302d
$2ee0:  cd 16 11            CALL     $1116
$2ee3:  cd e0 1c            CALL     $1ce0
$2ee6:  c3 b4 2e            JMP      $2eb4

F_M_2ee9:
$2ee9:  21 00 00            LXI      H,$0000
$2eec:  22 54 62            SHLD     $6254
$2eef:  3a 44 62            LDA      $6244
$2ef2:  a7                  ANA      A
$2ef3:  ca 07 2f            JZ       $2f07
$2ef6:  2a 3a 62            LHLD     $623a
$2ef9:  eb                  XCHG
$2efa:  2a 3e 62            LHLD     $623e
$2efd:  22 3a 62            SHLD     $623a
$2f00:  eb                  XCHG
$2f01:  22 3e 62            SHLD     $623e
$2f04:  c3 9b 2c            JMP      $2c9b

F_M_2f07:
$2f07:  3a 46 62            LDA      $6246
$2f0a:  a7                  ANA      A
$2f0b:  ca 47 2f            JZ       $2f47
$2f0e:  2a 3e 62            LHLD     $623e
$2f11:  22 5d 63            SHLD     $635d
$2f14:  2a 40 62            LHLD     $6240
$2f17:  22 5f 63            SHLD     $635f
$2f1a:  cd 0c 11            CALL     $110c
$2f1d:  cd e0 1c            CALL     $1ce0
$2f20:  cd 16 11            CALL     $1116
$2f23:  2a 3c 62            LHLD     $623c
$2f26:  22 5f 63            SHLD     $635f
$2f29:  cd e0 1c            CALL     $1ce0
$2f2c:  2a 3a 62            LHLD     $623a
$2f2f:  22 5d 63            SHLD     $635d
$2f32:  cd e0 1c            CALL     $1ce0
$2f35:  2a 40 62            LHLD     $6240
$2f38:  22 5f 63            SHLD     $635f
$2f3b:  cd e0 1c            CALL     $1ce0
$2f3e:  2a 3e 62            LHLD     $623e
$2f41:  22 5d 63            SHLD     $635d
$2f44:  cd e0 1c            CALL     $1ce0

F_M_2f47:
$2f47:  cd 0c 11            CALL     $110c
$2f4a:  2a 32 62            LHLD     $6232
$2f4d:  22 5d 63            SHLD     $635d
$2f50:  2a 34 62            LHLD     $6234
$2f53:  22 5f 63            SHLD     $635f
$2f56:  cd e0 1c            CALL     $1ce0
$2f59:  cd 88 02            CALL     $0288
$2f5c:  c9                  RET

F_M_2f5d:
$2f5d:  2a 4c 62            LHLD     $624c
$2f60:  eb                  XCHG
$2f61:  2a 3e 62            LHLD     $623e
$2f64:  cd 09 31            CALL     $3109
$2f67:  ca 96 2f            JZ       $2f96
$2f6a:  2a 42 62            LHLD     $6242
$2f6d:  eb                  XCHG
$2f6e:  19                  DAD      D
$2f6f:  22 4c 62            SHLD     $624c
$2f72:  eb                  XCHG
$2f73:  2a 3e 62            LHLD     $623e
$2f76:  cd 09 31            CALL     $3109
$2f79:  ca b5 2f            JZ       $2fb5
$2f7c:  d2 b5 2f            JNC      $2fb5
$2f7f:  eb                  XCHG
$2f80:  cd fe 30            CALL     $30fe
$2f83:  eb                  XCHG
$2f84:  2a 4e 62            LHLD     $624e
$2f87:  cd fe 30            CALL     $30fe
$2f8a:  22 4e 62            SHLD     $624e
$2f8d:  2a 3e 62            LHLD     $623e
$2f90:  22 4c 62            SHLD     $624c
$2f93:  c3 b5 2f            JMP      $2fb5

F_M_2f96:
$2f96:  2a 42 62            LHLD     $6242
$2f99:  eb                  XCHG
$2f9a:  2a 4e 62            LHLD     $624e
$2f9d:  cd fe 30            CALL     $30fe
$2fa0:  22 4e 62            SHLD     $624e
$2fa3:  eb                  XCHG
$2fa4:  2a 40 62            LHLD     $6240
$2fa7:  cd 09 31            CALL     $3109
$2faa:  da b5 2f            JC       $2fb5
$2fad:  3e 01               MVI      A,$01
$2faf:  32 54 62            STA      $6254
$2fb2:  c3 c1 2f            JMP      $2fc1

F_M_2fb5:
$2fb5:  2a 4c 62            LHLD     $624c
$2fb8:  22 5d 63            SHLD     $635d
$2fbb:  2a 4e 62            LHLD     $624e
$2fbe:  22 5f 63            SHLD     $635f

F_M_2fc1:
$2fc1:  c9                  RET

F_M_2fc2:
$2fc2:  2a 52 62            LHLD     $6252
$2fc5:  eb                  XCHG
$2fc6:  2a 40 62            LHLD     $6240
$2fc9:  cd 09 31            CALL     $3109
$2fcc:  ca 03 30            JZ       $3003
$2fcf:  2a 42 62            LHLD     $6242
$2fd2:  cd f3 30            CALL     $30f3
$2fd5:  19                  DAD      D
$2fd6:  da df 2f            JC       $2fdf
$2fd9:  cd f3 30            CALL     $30f3
$2fdc:  c3 f2 2f            JMP      $2ff2

F_M_2fdf:
$2fdf:  22 52 62            SHLD     $6252
$2fe2:  eb                  XCHG
$2fe3:  2a 40 62            LHLD     $6240
$2fe6:  cd 09 31            CALL     $3109
$2fe9:  ca 20 30            JZ       $3020
$2fec:  da 20 30            JC       $3020
$2fef:  cd fe 30            CALL     $30fe

F_M_2ff2:
$2ff2:  eb                  XCHG
$2ff3:  2a 50 62            LHLD     $6250
$2ff6:  19                  DAD      D
$2ff7:  22 50 62            SHLD     $6250
$2ffa:  2a 40 62            LHLD     $6240
$2ffd:  22 52 62            SHLD     $6252
$3000:  c3 20 30            JMP      $3020

F_M_3003:
$3003:  2a 42 62            LHLD     $6242
$3006:  eb                  XCHG
$3007:  2a 50 62            LHLD     $6250
$300a:  19                  DAD      D
$300b:  22 50 62            SHLD     $6250
$300e:  eb                  XCHG
$300f:  2a 3e 62            LHLD     $623e
$3012:  cd 09 31            CALL     $3109
$3015:  d2 20 30            JNC      $3020
$3018:  3e 01               MVI      A,$01
$301a:  32 54 62            STA      $6254
$301d:  c3 2c 30            JMP      $302c

F_M_3020:
$3020:  2a 50 62            LHLD     $6250
$3023:  22 5d 63            SHLD     $635d
$3026:  2a 52 62            LHLD     $6252
$3029:  22 5f 63            SHLD     $635f

F_M_302c:
$302c:  c9                  RET

F_M_302d:
$302d:  2a 4c 62            LHLD     $624c
$3030:  eb                  XCHG
$3031:  2a 3e 62            LHLD     $623e
$3034:  cd 09 31            CALL     $3109
$3037:  ca 63 30            JZ       $3063
$303a:  2a 42 62            LHLD     $6242
$303d:  19                  DAD      D
$303e:  22 4c 62            SHLD     $624c
$3041:  eb                  XCHG
$3042:  2a 3e 62            LHLD     $623e
$3045:  cd 09 31            CALL     $3109
$3048:  ca 80 30            JZ       $3080
$304b:  d2 80 30            JNC      $3080
$304e:  eb                  XCHG
$304f:  cd fe 30            CALL     $30fe
$3052:  eb                  XCHG
$3053:  2a 4e 62            LHLD     $624e
$3056:  19                  DAD      D
$3057:  22 4e 62            SHLD     $624e
$305a:  2a 3e 62            LHLD     $623e
$305d:  22 4c 62            SHLD     $624c
$3060:  c3 80 30            JMP      $3080

F_M_3063:
$3063:  2a 42 62            LHLD     $6242
$3066:  eb                  XCHG
$3067:  2a 4e 62            LHLD     $624e
$306a:  19                  DAD      D
$306b:  22 4e 62            SHLD     $624e
$306e:  eb                  XCHG
$306f:  2a 40 62            LHLD     $6240
$3072:  cd 09 31            CALL     $3109
$3075:  d2 80 30            JNC      $3080
$3078:  3e 01               MVI      A,$01
$307a:  32 54 62            STA      $6254
$307d:  c3 8c 30            JMP      $308c

F_M_3080:
$3080:  2a 4c 62            LHLD     $624c
$3083:  22 5d 63            SHLD     $635d
$3086:  2a 4e 62            LHLD     $624e
$3089:  22 5f 63            SHLD     $635f

F_M_308c:
$308c:  c9                  RET

F_M_308d:
$308d:  2a 52 62            LHLD     $6252
$3090:  eb                  XCHG
$3091:  2a 40 62            LHLD     $6240
$3094:  cd 09 31            CALL     $3109
$3097:  ca c3 30            JZ       $30c3
$309a:  2a 42 62            LHLD     $6242
$309d:  19                  DAD      D
$309e:  22 52 62            SHLD     $6252
$30a1:  eb                  XCHG
$30a2:  2a 40 62            LHLD     $6240
$30a5:  cd 09 31            CALL     $3109
$30a8:  ca e6 30            JZ       $30e6
$30ab:  d2 e6 30            JNC      $30e6
$30ae:  eb                  XCHG
$30af:  cd fe 30            CALL     $30fe
$30b2:  eb                  XCHG
$30b3:  2a 50 62            LHLD     $6250
$30b6:  19                  DAD      D
$30b7:  22 50 62            SHLD     $6250
$30ba:  2a 40 62            LHLD     $6240
$30bd:  22 52 62            SHLD     $6252
$30c0:  c3 e6 30            JMP      $30e6

F_M_30c3:
$30c3:  2a 42 62            LHLD     $6242
$30c6:  eb                  XCHG
$30c7:  2a 50 62            LHLD     $6250
$30ca:  19                  DAD      D
$30cb:  22 50 62            SHLD     $6250
$30ce:  eb                  XCHG
$30cf:  2a 3e 62            LHLD     $623e
$30d2:  cd 09 31            CALL     $3109
$30d5:  d2 e6 30            JNC      $30e6
$30d8:  3e 01               MVI      A,$01
$30da:  32 54 62            STA      $6254
$30dd:  c3 f2 30            JMP      $30f2
$30e0:  2a           DB  $2a
$30e1:  40           DB  $40
$30e2:  62           DB  $62
$30e3:  22           DB  $22
$30e4:  52           DB  $52
$30e5:  62           DB  $62

F_M_30e6:
$30e6:  2a 50 62            LHLD     $6250
$30e9:  22 5d 63            SHLD     $635d
$30ec:  2a 52 62            LHLD     $6252
$30ef:  22 5f 63            SHLD     $635f

F_M_30f2:
$30f2:  c9                  RET

F_M_30f3:
$30f3:  7d                  MOV      A,L
$30f4:  2f                  CMA
$30f5:  6f                  MOV      L,A
$30f6:  7c                  MOV      A,H
$30f7:  2f                  CMA
$30f8:  67                  MOV      H,A
$30f9:  01 01 00            LXI      B,$0001
$30fc:  09                  DAD      B
$30fd:  c9                  RET

F_M_30fe:
$30fe:  7d                  MOV      A,L
$30ff:  93                  SUB      E
$3100:  6f                  MOV      L,A
$3101:  7c                  MOV      A,H
$3102:  9a                  SBB      D
$3103:  67                  MOV      H,A
$3104:  f0                  RP
$3105:  21 00 00            LXI      H,$0000
$3108:  c9                  RET

F_M_3109:
$3109:  7c                  MOV      A,H
$310a:  ba                  CMP      D
$310b:  c0                  RNZ
$310c:  7d                  MOV      A,L
$310d:  bb                  CMP      E
$310e:  c9                  RET

F_M_310f:
$310f:  2a cc 61            LHLD     $61cc
$3112:  22 ee 61            SHLD     $61ee
$3115:  2a 30 62            LHLD     $6230
$3118:  22 3e 62            SHLD     $623e
$311b:  2a ea 61            LHLD     $61ea
$311e:  22 f0 61            SHLD     $61f0
$3121:  2a 4e 63            LHLD     $634e
$3124:  22 d8 61            SHLD     $61d8
$3127:  2a 50 63            LHLD     $6350
$312a:  22 da 61            SHLD     $61da
$312d:  2a d6 61            LHLD     $61d6
$3130:  22 46 62            SHLD     $6246
$3133:  2a d4 61            LHLD     $61d4
$3136:  22 42 62            SHLD     $6242
$3139:  2a ce 61            LHLD     $61ce
$313c:  22 44 62            SHLD     $6244
$313f:  11 b4 00            LXI      D,$00b4
$3142:  2a cc 61            LHLD     $61cc
$3145:  7c                  MOV      A,H
$3146:  a7                  ANA      A
$3147:  f2 50 31            JP       $3150
$314a:  e6 7f               ANI      $7f
$314c:  67                  MOV      H,A
$314d:  11 00 00            LXI      D,$0000

F_M_3150:
$3150:  22 ee 61            SHLD     $61ee
$3153:  3a 44 62            LDA      $6244
$3156:  e6 01               ANI      $01
$3158:  ca 69 31            JZ       $3169
$315b:  3a 44 62            LDA      $6244
$315e:  e6 fe               ANI      $fe
$3160:  32 44 62            STA      $6244
$3163:  21 00 00            LXI      H,$0000
$3166:  c3 a8 31            JMP      $31a8

F_M_3169:
$3169:  3a 44 62            LDA      $6244
$316c:  e6 02               ANI      $02
$316e:  ca 7c 31            JZ       $317c
$3171:  3a 44 62            LDA      $6244
$3174:  e6 fd               ANI      $fd
$3176:  21 2d 00            LXI      H,$002d
$3179:  c3 9f 31            JMP      $319f

F_M_317c:
$317c:  3a 44 62            LDA      $6244
$317f:  e6 04               ANI      $04
$3181:  ca 8f 31            JZ       $318f
$3184:  3a 44 62            LDA      $6244
$3187:  e6 fb               ANI      $fb
$3189:  21 5a 00            LXI      H,$005a
$318c:  c3 9f 31            JMP      $319f

F_M_318f:
$318f:  3a 44 62            LDA      $6244
$3192:  e6 08               ANI      $08
$3194:  ca 18 34            JZ       $3418
$3197:  3a 44 62            LDA      $6244
$319a:  e6 f7               ANI      $f7
$319c:  21 87 00            LXI      H,$0087

F_M_319f:
$319f:  32 44 62            STA      $6244
$31a2:  eb                  XCHG
$31a3:  19                  DAD      D
$31a4:  eb                  XCHG
$31a5:  cd 02 36            CALL     $3602

F_M_31a8:
$31a8:  22 2a 62            SHLD     $622a
$31ab:  2a 30 62            LHLD     $6230
$31ae:  7c                  MOV      A,H
$31af:  a7                  ANA      A
$31b0:  f2 b9 31            JP       $31b9
$31b3:  e6 7f               ANI      $7f
$31b5:  67                  MOV      H,A
$31b6:  c3 bc 31            JMP      $31bc

F_M_31b9:
$31b9:  cd 02 36            CALL     $3602

F_M_31bc:
$31bc:  19                  DAD      D
$31bd:  cd 33 34            CALL     $3433
$31c0:  22 d0 61            SHLD     $61d0
$31c3:  eb                  XCHG
$31c4:  2a ea 61            LHLD     $61ea
$31c7:  7c                  MOV      A,H
$31c8:  a7                  ANA      A
$31c9:  f2 d2 31            JP       $31d2
$31cc:  e6 7f               ANI      $7f
$31ce:  67                  MOV      H,A
$31cf:  c3 d5 31            JMP      $31d5

F_M_31d2:
$31d2:  cd 02 36            CALL     $3602

F_M_31d5:
$31d5:  19                  DAD      D
$31d6:  11 68 01            LXI      D,$0168
$31d9:  7c                  MOV      A,H
$31da:  a7                  ANA      A
$31db:  f2 e2 31            JP       $31e2
$31de:  19                  DAD      D
$31df:  c3 eb 31            JMP      $31eb

F_M_31e2:
$31e2:  cd e5 35            CALL     $35e5
$31e5:  da f0 31            JC       $31f0
$31e8:  cd f0 27            CALL     $27f0

F_M_31eb:
$31eb:  3e 01               MVI      A,$01
$31ed:  32 02 62            STA      $6202

F_M_31f0:
$31f0:  eb                  XCHG
$31f1:  2a d0 61            LHLD     $61d0
$31f4:  cd e5 35            CALL     $35e5
$31f7:  da fb 31            JC       $31fb
$31fa:  eb                  XCHG

F_M_31fb:
$31fb:  3a 02 62            LDA      $6202
$31fe:  a7                  ANA      A
$31ff:  ca 03 32            JZ       $3203
$3202:  eb                  XCHG

F_M_3203:
$3203:  22 d0 61            SHLD     $61d0
$3206:  eb                  XCHG
$3207:  22 d2 61            SHLD     $61d2
$320a:  2a d0 61            LHLD     $61d0
$320d:  cd bc 34            CALL     $34bc
$3210:  2a d8 61            LHLD     $61d8
$3213:  eb                  XCHG
$3214:  2a 06 62            LHLD     $6206
$3217:  cd e5 35            CALL     $35e5
$321a:  d2 1e 32            JNC      $321e
$321d:  eb                  XCHG

F_M_321e:
$321e:  22 f6 61            SHLD     $61f6
$3221:  eb                  XCHG
$3222:  22 f2 61            SHLD     $61f2
$3225:  2a da 61            LHLD     $61da
$3228:  eb                  XCHG
$3229:  2a 08 62            LHLD     $6208
$322c:  cd e5 35            CALL     $35e5
$322f:  d2 33 32            JNC      $3233
$3232:  eb                  XCHG

F_M_3233:
$3233:  22 f8 61            SHLD     $61f8
$3236:  eb                  XCHG
$3237:  22 f4 61            SHLD     $61f4
$323a:  2a d2 61            LHLD     $61d2
$323d:  cd bc 34            CALL     $34bc
$3240:  2a d8 61            LHLD     $61d8
$3243:  eb                  XCHG
$3244:  2a 06 62            LHLD     $6206
$3247:  cd e5 35            CALL     $35e5
$324a:  d2 4e 32            JNC      $324e
$324d:  eb                  XCHG

F_M_324e:
$324e:  22 fe 61            SHLD     $61fe
$3251:  eb                  XCHG
$3252:  22 fa 61            SHLD     $61fa
$3255:  2a da 61            LHLD     $61da
$3258:  eb                  XCHG
$3259:  2a 08 62            LHLD     $6208
$325c:  cd e5 35            CALL     $35e5
$325f:  d2 63 32            JNC      $3263
$3262:  eb                  XCHG

F_M_3263:
$3263:  22 00 62            SHLD     $6200
$3266:  eb                  XCHG
$3267:  22 fc 61            SHLD     $61fc
$326a:  2a d0 61            LHLD     $61d0
$326d:  cd 4c 34            CALL     $344c
$3270:  22 0c 62            SHLD     $620c
$3273:  2a d2 61            LHLD     $61d2
$3276:  cd 4c 34            CALL     $344c
$3279:  22 0e 62            SHLD     $620e
$327c:  2a ee 61            LHLD     $61ee
$327f:  eb                  XCHG
$3280:  2a da 61            LHLD     $61da
$3283:  19                  DAD      D
$3284:  22 4a 62            SHLD     $624a
$3287:  2a da 61            LHLD     $61da
$328a:  cd f0 27            CALL     $27f0
$328d:  22 04 62            SHLD     $6204
$3290:  2a 42 62            LHLD     $6242
$3293:  cd 02 36            CALL     $3602
$3296:  22 42 62            SHLD     $6242
$3299:  af                  XRA      A
$329a:  32 10 62            STA      $6210

F_M_329d:
$329d:  2a 42 62            LHLD     $6242
$32a0:  eb                  XCHG
$32a1:  2a 4a 62            LHLD     $624a
$32a4:  19                  DAD      D
$32a5:  22 4a 62            SHLD     $624a
$32a8:  eb                  XCHG
$32a9:  2a 04 62            LHLD     $6204
$32ac:  cd e5 35            CALL     $35e5
$32af:  da b5 32            JC       $32b5
$32b2:  c3 15 34            JMP      $3415

F_M_32b5:
$32b5:  2a da 61            LHLD     $61da
$32b8:  cd e5 35            CALL     $35e5
$32bb:  da c3 32            JC       $32c3
$32be:  3e 01               MVI      A,$01
$32c0:  32 10 62            STA      $6210

F_M_32c3:
$32c3:  2a 4a 62            LHLD     $624a
$32c6:  eb                  XCHG
$32c7:  2a da 61            LHLD     $61da
$32ca:  cd e5 35            CALL     $35e5
$32cd:  d2 d1 32            JNC      $32d1
$32d0:  eb                  XCHG

F_M_32d1:
$32d1:  cd f0 27            CALL     $27f0
$32d4:  22 4e 62            SHLD     $624e
$32d7:  2a ee 61            LHLD     $61ee
$32da:  eb                  XCHG
$32db:  2a 4e 62            LHLD     $624e
$32de:  cd e3 28            CALL     $28e3
$32e1:  7c                  MOV      A,H
$32e2:  a7                  ANA      A
$32e3:  1f                  RAR
$32e4:  67                  MOV      H,A
$32e5:  7d                  MOV      A,L
$32e6:  1f                  RAR
$32e7:  6f                  MOV      L,A
$32e8:  22 0a 62            SHLD     $620a
$32eb:  3e 00               MVI      A,$00
$32ed:  32 e2 61            STA      $61e2
$32f0:  21 c2 40            LXI      H,$40c2

F_M_32f3:
$32f3:  5e                  MOV      E,M
$32f4:  23                  INX      H
$32f5:  56                  MOV      D,M
$32f6:  23                  INX      H
$32f7:  e5                  PUSH     H
$32f8:  c1                  POP      B
$32f9:  2a 0a 62            LHLD     $620a
$32fc:  cd e5 35            CALL     $35e5
$32ff:  da 0e 33            JC       $330e
$3302:  c5                  PUSH     B
$3303:  e1                  POP      H
$3304:  3a e2 61            LDA      $61e2
$3307:  3c                  INR      A
$3308:  32 e2 61            STA      $61e2
$330b:  c3 f3 32            JMP      $32f3

F_M_330e:
$330e:  2a e2 61            LHLD     $61e2
$3311:  3a 10 62            LDA      $6210
$3314:  fe 01               CPI      $01
$3316:  c2 1d 33            JNZ      $331d
$3319:  11 b4 00            LXI      D,$00b4
$331c:  19                  DAD      D

F_M_331d:
$331d:  eb                  XCHG
$331e:  cd 79 35            CALL     $3579
$3321:  2a e2 61            LHLD     $61e2
$3324:  eb                  XCHG
$3325:  21 b4 00            LXI      H,$00b4
$3328:  cd f0 27            CALL     $27f0
$332b:  3a 10 62            LDA      $6210
$332e:  fe 01               CPI      $01
$3330:  c2 38 33            JNZ      $3338
$3333:  eb                  XCHG
$3334:  21 b4 00            LXI      H,$00b4
$3337:  19                  DAD      D

F_M_3338:
$3338:  eb                  XCHG
$3339:  cd 79 35            CALL     $3579
$333c:  2a 4a 62            LHLD     $624a
$333f:  eb                  XCHG
$3340:  2a f8 61            LHLD     $61f8
$3343:  cd e5 35            CALL     $35e5
$3346:  da 60 33            JC       $3360
$3349:  2a 0c 62            LHLD     $620c
$334c:  e5                  PUSH     H
$334d:  c1                  POP      B
$334e:  2a d0 61            LHLD     $61d0
$3351:  22 26 62            SHLD     $6226
$3354:  2a f4 61            LHLD     $61f4
$3357:  cd e5 35            CALL     $35e5
$335a:  d2 60 33            JNC      $3360
$335d:  cd a9 35            CALL     $35a9

F_M_3360:
$3360:  2a 4a 62            LHLD     $624a
$3363:  eb                  XCHG
$3364:  2a 00 62            LHLD     $6200
$3367:  cd e5 35            CALL     $35e5
$336a:  da 84 33            JC       $3384
$336d:  2a 0e 62            LHLD     $620e
$3370:  e5                  PUSH     H
$3371:  c1                  POP      B
$3372:  2a d2 61            LHLD     $61d2
$3375:  22 26 62            SHLD     $6226
$3378:  2a fc 61            LHLD     $61fc
$337b:  cd e5 35            CALL     $35e5
$337e:  d2 84 33            JNC      $3384
$3381:  cd a9 35            CALL     $35a9

F_M_3384:
$3384:  3a 2a 62            LDA      $622a
$3387:  fe 5a               CPI      $5a
$3389:  ca 96 33            JZ       $3396
$338c:  2a 18 62            LHLD     $6218
$338f:  eb                  XCHG
$3390:  2a 14 62            LHLD     $6214
$3393:  c3 9d 33            JMP      $339d

F_M_3396:
$3396:  2a 1a 62            LHLD     $621a
$3399:  eb                  XCHG
$339a:  2a 16 62            LHLD     $6216

F_M_339d:
$339d:  cd 69 34            CALL     $3469
$33a0:  22 2c 62            SHLD     $622c
$33a3:  3a 24 62            LDA      $6224
$33a6:  fe 02               CPI      $02
$33a8:  ca ca 33            JZ       $33ca
$33ab:  3a 2a 62            LDA      $622a
$33ae:  fe 5a               CPI      $5a
$33b0:  ca bd 33            JZ       $33bd
$33b3:  2a 20 62            LHLD     $6220
$33b6:  eb                  XCHG
$33b7:  2a 1c 62            LHLD     $621c
$33ba:  c3 c4 33            JMP      $33c4

F_M_33bd:
$33bd:  2a 22 62            LHLD     $6222
$33c0:  eb                  XCHG
$33c1:  2a 1e 62            LHLD     $621e

F_M_33c4:
$33c4:  cd 69 34            CALL     $3469
$33c7:  22 2e 62            SHLD     $622e

F_M_33ca:
$33ca:  cd 0c 11            CALL     $110c
$33cd:  2a 2c 62            LHLD     $622c
$33d0:  eb                  XCHG
$33d1:  21 14 62            LXI      H,$6214
$33d4:  cd 80 34            CALL     $3480
$33d7:  3a 24 62            LDA      $6224
$33da:  fe 02               CPI      $02
$33dc:  ca fa 33            JZ       $33fa
$33df:  cd 16 11            CALL     $1116
$33e2:  2a 2e 62            LHLD     $622e
$33e5:  eb                  XCHG
$33e6:  21 1c 62            LXI      H,$621c
$33e9:  cd 80 34            CALL     $3480
$33ec:  cd 0c 11            CALL     $110c
$33ef:  2a 2e 62            LHLD     $622e
$33f2:  eb                  XCHG
$33f3:  5a                  MOV      E,D
$33f4:  21 1c 62            LXI      H,$621c
$33f7:  cd 80 34            CALL     $3480

F_M_33fa:
$33fa:  cd 16 11            CALL     $1116
$33fd:  2a 2c 62            LHLD     $622c
$3400:  eb                  XCHG
$3401:  5a                  MOV      E,D
$3402:  21 14 62            LXI      H,$6214
$3405:  cd 80 34            CALL     $3480
$3408:  3a 12 62            LDA      $6212
$340b:  2f                  CMA
$340c:  32 12 62            STA      $6212
$340f:  21 00 00            LXI      H,$0000
$3412:  22 24 62            SHLD     $6224

F_M_3415:
$3415:  c3 9d 32            JMP      $329d

F_M_3418:
$3418:  c9                  RET

F_M_3419:
$3419:  11 5a 00            LXI      D,$005a
$341c:  3e 01               MVI      A,$01

F_M_341e:
$341e:  32 e8 61            STA      $61e8
$3421:  22 e2 61            SHLD     $61e2
$3424:  cd e5 35            CALL     $35e5
$3427:  d8                  RC
$3428:  cd f0 27            CALL     $27f0
$342b:  3a e8 61            LDA      $61e8
$342e:  3c                  INR      A
$342f:  c3 1e 34            JMP      $341e
$3432:  c9           DB  $c9

F_M_3433:
$3433:  11 68 01            LXI      D,$0168
$3436:  7c                  MOV      A,H
$3437:  a7                  ANA      A
$3438:  f2 3c 34            JP       $343c
$343b:  19                  DAD      D

F_M_343c:
$343c:  cd e5 35            CALL     $35e5
$343f:  d8                  RC
$3440:  cd f0 27            CALL     $27f0
$3443:  c9                  RET

F_M_3444:
$3444:  2a 2a 62            LHLD     $622a
$3447:  19                  DAD      D
$3448:  cd 33 34            CALL     $3433
$344b:  c9                  RET

F_M_344c:
$344c:  cd 19 34            CALL     $3419
$344f:  3a e8 61            LDA      $61e8
$3452:  e6 01               ANI      $01
$3454:  c2 5b 34            JNZ      $345b
$3457:  eb                  XCHG
$3458:  cd f0 27            CALL     $27f0

F_M_345b:
$345b:  7d                  MOV      A,L
$345c:  07                  RLC
$345d:  5f                  MOV      E,A
$345e:  16 00               MVI      D,$00
$3460:  21 c2 40            LXI      H,$40c2
$3463:  19                  DAD      D
$3464:  5e                  MOV      E,M
$3465:  23                  INX      H
$3466:  56                  MOV      D,M
$3467:  eb                  XCHG
$3468:  c9                  RET

F_M_3469:
$3469:  cd e5 35            CALL     $35e5
$346c:  11 04 00            LXI      D,$0004
$346f:  21 00 00            LXI      H,$0000
$3472:  da 76 34            JC       $3476
$3475:  eb                  XCHG

F_M_3476:
$3476:  3a 12 62            LDA      $6212
$3479:  a7                  ANA      A
$347a:  ca 7e 34            JZ       $347e
$347d:  eb                  XCHG

F_M_347e:
$347e:  63                  MOV      H,E
$347f:  c9                  RET

F_M_3480:
$3480:  16 00               MVI      D,$00
$3482:  19                  DAD      D
$3483:  5e                  MOV      E,M
$3484:  23                  INX      H
$3485:  56                  MOV      D,M
$3486:  23                  INX      H
$3487:  eb                  XCHG
$3488:  22 5d 63            SHLD     $635d
$348b:  eb                  XCHG
$348c:  5e                  MOV      E,M
$348d:  23                  INX      H
$348e:  56                  MOV      D,M
$348f:  eb                  XCHG
$3490:  22 5f 63            SHLD     $635f
$3493:  cd e0 1c            CALL     $1ce0
$3496:  c9                  RET

F_M_3497:
$3497:  2a 24 62            LHLD     $6224
$349a:  7d                  MOV      A,L
$349b:  07                  RLC
$349c:  6f                  MOV      L,A
$349d:  eb                  XCHG
$349e:  21 14 62            LXI      H,$6214
$34a1:  19                  DAD      D
$34a2:  eb                  XCHG
$34a3:  2a 06 62            LHLD     $6206
$34a6:  eb                  XCHG
$34a7:  73                  MOV      M,E
$34a8:  23                  INX      H
$34a9:  72                  MOV      M,D
$34aa:  23                  INX      H
$34ab:  eb                  XCHG
$34ac:  2a 08 62            LHLD     $6208
$34af:  eb                  XCHG
$34b0:  73                  MOV      M,E
$34b1:  23                  INX      H
$34b2:  72                  MOV      M,D
$34b3:  3a 24 62            LDA      $6224
$34b6:  3c                  INR      A
$34b7:  3c                  INR      A
$34b8:  32 24 62            STA      $6224
$34bb:  c9                  RET

F_M_34bc:
$34bc:  cd 19 34            CALL     $3419
$34bf:  3a e2 61            LDA      $61e2
$34c2:  07                  RLC
$34c3:  5f                  MOV      E,A
$34c4:  16 00               MVI      D,$00
$34c6:  21 76 41            LXI      H,$4176
$34c9:  cd f0 27            CALL     $27f0
$34cc:  5e                  MOV      E,M
$34cd:  23                  INX      H
$34ce:  56                  MOV      D,M
$34cf:  2a ee 61            LHLD     $61ee
$34d2:  cd 57 29            CALL     $2957
$34d5:  cd eb 35            CALL     $35eb
$34d8:  22 e6 61            SHLD     $61e6
$34db:  21 c2 40            LXI      H,$40c2
$34de:  3a e2 61            LDA      $61e2
$34e1:  07                  RLC
$34e2:  5f                  MOV      E,A
$34e3:  16 00               MVI      D,$00
$34e5:  19                  DAD      D
$34e6:  5e                  MOV      E,M
$34e7:  23                  INX      H
$34e8:  56                  MOV      D,M
$34e9:  2a ee 61            LHLD     $61ee
$34ec:  cd 57 29            CALL     $2957
$34ef:  cd eb 35            CALL     $35eb
$34f2:  22 e4 61            SHLD     $61e4
$34f5:  3a e8 61            LDA      $61e8
$34f8:  fe 01               CPI      $01
$34fa:  c2 1a 35            JNZ      $351a
$34fd:  2a e6 61            LHLD     $61e6
$3500:  eb                  XCHG
$3501:  2a d8 61            LHLD     $61d8
$3504:  cd f0 27            CALL     $27f0
$3507:  22 06 62            SHLD     $6206
$350a:  2a e4 61            LHLD     $61e4
$350d:  eb                  XCHG
$350e:  2a da 61            LHLD     $61da
$3511:  cd da 35            CALL     $35da
$3514:  22 08 62            SHLD     $6208
$3517:  c3 78 35            JMP      $3578

F_M_351a:
$351a:  fe 02               CPI      $02
$351c:  c2 3c 35            JNZ      $353c
$351f:  2a e4 61            LHLD     $61e4
$3522:  eb                  XCHG
$3523:  2a d8 61            LHLD     $61d8
$3526:  cd da 35            CALL     $35da
$3529:  22 06 62            SHLD     $6206
$352c:  2a e6 61            LHLD     $61e6
$352f:  eb                  XCHG
$3530:  2a da 61            LHLD     $61da
$3533:  cd da 35            CALL     $35da
$3536:  22 08 62            SHLD     $6208
$3539:  c3 78 35            JMP      $3578

F_M_353c:
$353c:  fe 03               CPI      $03
$353e:  c2 5e 35            JNZ      $355e
$3541:  2a e6 61            LHLD     $61e6
$3544:  eb                  XCHG
$3545:  2a d8 61            LHLD     $61d8
$3548:  cd da 35            CALL     $35da
$354b:  22 06 62            SHLD     $6206
$354e:  2a e4 61            LHLD     $61e4
$3551:  eb                  XCHG
$3552:  2a da 61            LHLD     $61da
$3555:  cd f0 27            CALL     $27f0
$3558:  22 08 62            SHLD     $6208
$355b:  c3 78 35            JMP      $3578

F_M_355e:
$355e:  2a e4 61            LHLD     $61e4
$3561:  eb                  XCHG
$3562:  2a d8 61            LHLD     $61d8
$3565:  cd f0 27            CALL     $27f0
$3568:  22 06 62            SHLD     $6206
$356b:  2a e6 61            LHLD     $61e6
$356e:  eb                  XCHG
$356f:  2a da 61            LHLD     $61da
$3572:  cd f0 27            CALL     $27f0
$3575:  22 08 62            SHLD     $6208

F_M_3578:
$3578:  c9                  RET

F_M_3579:
$3579:  2a d2 61            LHLD     $61d2
$357c:  3a 02 62            LDA      $6202
$357f:  a7                  ANA      A
$3580:  ca 93 35            JZ       $3593
$3583:  cd e5 35            CALL     $35e5
$3586:  d2 9f 35            JNC      $359f
$3589:  2a d0 61            LHLD     $61d0
$358c:  cd e5 35            CALL     $35e5
$358f:  da 9f 35            JC       $359f
$3592:  c9                  RET

F_M_3593:
$3593:  cd e5 35            CALL     $35e5
$3596:  c8                  RZ
$3597:  d8                  RC
$3598:  2a d0 61            LHLD     $61d0
$359b:  cd e5 35            CALL     $35e5
$359e:  d0                  RNC

F_M_359f:
$359f:  cd 44 34            CALL     $3444
$35a2:  cd bc 34            CALL     $34bc
$35a5:  cd 97 34            CALL     $3497
$35a8:  c9                  RET

F_M_35a9:
$35a9:  eb                  XCHG
$35aa:  cd f0 27            CALL     $27f0
$35ad:  c5                  PUSH     B
$35ae:  d1                  POP      D
$35af:  cd e3 28            CALL     $28e3
$35b2:  7b                  MOV      A,E
$35b3:  1f                  RAR
$35b4:  7c                  MOV      A,H
$35b5:  1f                  RAR
$35b6:  67                  MOV      H,A
$35b7:  7d                  MOV      A,L
$35b8:  1f                  RAR
$35b9:  6f                  MOV      L,A
$35ba:  eb                  XCHG
$35bb:  2a ee 61            LHLD     $61ee
$35be:  22 cc 61            SHLD     $61cc
$35c1:  eb                  XCHG
$35c2:  22 ee 61            SHLD     $61ee
$35c5:  2a 26 62            LHLD     $6226
$35c8:  eb                  XCHG
$35c9:  cd 44 34            CALL     $3444
$35cc:  cd bc 34            CALL     $34bc
$35cf:  cd 97 34            CALL     $3497
$35d2:  00                  NOP
$35d3:  2a cc 61            LHLD     $61cc
$35d6:  22 ee 61            SHLD     $61ee
$35d9:  c9                  RET

F_M_35da:
$35da:  19                  DAD      D
$35db:  7a                  MOV      A,D
$35dc:  a7                  ANA      A
$35dd:  17                  RAL
$35de:  d2 e4 35            JNC      $35e4
$35e1:  21 ff 7f            LXI      H,$7fff

F_M_35e4:
$35e4:  c9                  RET

F_M_35e5:
$35e5:  7c                  MOV      A,H
$35e6:  ba                  CMP      D
$35e7:  c0                  RNZ
$35e8:  7d                  MOV      A,L
$35e9:  bb                  CMP      E
$35ea:  c9                  RET

F_M_35eb:
$35eb:  7c                  MOV      A,H
$35ec:  a7                  ANA      A
$35ed:  17                  RAL
$35ee:  7b                  MOV      A,E
$35ef:  17                  RAL
$35f0:  5f                  MOV      E,A
$35f1:  7a                  MOV      A,D
$35f2:  17                  RAL
$35f3:  57                  MOV      D,A
$35f4:  d5                  PUSH     D
$35f5:  11 aa aa            LXI      D,$aaaa
$35f8:  19                  DAD      D
$35f9:  e1                  POP      H
$35fa:  d2 01 36            JNC      $3601
$35fd:  11 01 00            LXI      D,$0001
$3600:  19                  DAD      D

F_M_3601:
$3601:  c9                  RET

F_M_3602:
$3602:  7d                  MOV      A,L
$3603:  2f                  CMA
$3604:  6f                  MOV      L,A
$3605:  7c                  MOV      A,H
$3606:  2f                  CMA
$3607:  67                  MOV      H,A
$3608:  01 01 00            LXI      B,$0001
$360b:  09                  DAD      B
$360c:  c9                  RET
$360d:  7d                  MOV      A,L
$360e:  8b                  ADC      E
$360f:  6f                  MOV      L,A
$3610:  7c                  MOV      A,H
$3611:  8a                  ADC      D
$3612:  67                  MOV      H,A
$3613:  c9                  RET

F_M_3614:
$3614:  cd 7c 02            CALL     $027c
$3617:  21 00 00            LXI      H,$0000
$361a:  22 54 62            SHLD     $6254
$361d:  22 ea 61            SHLD     $61ea
$3620:  2a 4e 63            LHLD     $634e
$3623:  22 48 62            SHLD     $6248
$3626:  2a 50 63            LHLD     $6350
$3629:  22 4a 62            SHLD     $624a
$362c:  2a c2 61            LHLD     $61c2
$362f:  22 ca 61            SHLD     $61ca
$3632:  2a be 61            LHLD     $61be
$3635:  22 ec 61            SHLD     $61ec
$3638:  2a c6 61            LHLD     $61c6
$363b:  22 d8 61            SHLD     $61d8
$363e:  2a c8 61            LHLD     $61c8
$3641:  22 da 61            SHLD     $61da
$3644:  2a d8 61            LHLD     $61d8
$3647:  cd e3 38            CALL     $38e3
$364a:  eb                  XCHG
$364b:  2a 48 62            LHLD     $6248
$364e:  19                  DAD      D
$364f:  22 4c 62            SHLD     $624c
$3652:  2a da 61            LHLD     $61da
$3655:  cd e3 38            CALL     $38e3
$3658:  eb                  XCHG
$3659:  2a 4a 62            LHLD     $624a
$365c:  19                  DAD      D
$365d:  22 4e 62            SHLD     $624e
$3660:  2a 4c 62            LHLD     $624c
$3663:  7c                  MOV      A,H
$3664:  a7                  ANA      A
$3665:  fa 77 36            JM       $3677
$3668:  11 00 00            LXI      D,$0000
$366b:  cd c6 38            CALL     $38c6
$366e:  ca 86 36            JZ       $3686
$3671:  21 06 00            LXI      H,$0006
$3674:  f2 89 36            JP       $3689

F_M_3677:
$3677:  cd e3 38            CALL     $38e3
$367a:  22 4c 62            SHLD     $624c
$367d:  21 09 00            LXI      H,$0009
$3680:  22 e8 61            SHLD     $61e8
$3683:  c3 89 36            JMP      $3689

F_M_3686:
$3686:  21 0a 00            LXI      H,$000a

F_M_3689:
$3689:  22 e8 61            SHLD     $61e8
$368c:  2a 4e 62            LHLD     $624e
$368f:  7c                  MOV      A,H
$3690:  a7                  ANA      A
$3691:  fa a5 36            JM       $36a5
$3694:  11 00 00            LXI      D,$0000
$3697:  cd c6 38            CALL     $38c6
$369a:  3a e8 61            LDA      $61e8
$369d:  ca b3 36            JZ       $36b3
$36a0:  e6 03               ANI      $03
$36a2:  c3 b5 36            JMP      $36b5

F_M_36a5:
$36a5:  cd e3 38            CALL     $38e3
$36a8:  22 4e 62            SHLD     $624e
$36ab:  3a e8 61            LDA      $61e8
$36ae:  e6 0c               ANI      $0c
$36b0:  c3 b5 36            JMP      $36b5

F_M_36b3:
$36b3:  e6 05               ANI      $05

F_M_36b5:
$36b5:  fe 08               CPI      $08
$36b7:  c2 bf 36            JNZ      $36bf
$36ba:  3e 04               MVI      A,$04
$36bc:  c3 c6 36            JMP      $36c6

F_M_36bf:
$36bf:  fe 04               CPI      $04
$36c1:  c2 c6 36            JNZ      $36c6
$36c4:  3e 03               MVI      A,$03

F_M_36c6:
$36c6:  32 e8 61            STA      $61e8
$36c9:  2a 4c 62            LHLD     $624c
$36cc:  11 00 00            LXI      D,$0000
$36cf:  cd c6 38            CALL     $38c6
$36d2:  c2 db 36            JNZ      $36db
$36d5:  2a 4e 62            LHLD     $624e
$36d8:  c3 e7 36            JMP      $36e7

F_M_36db:
$36db:  2a 4e 62            LHLD     $624e
$36de:  cd c6 38            CALL     $38c6
$36e1:  c2 f3 36            JNZ      $36f3
$36e4:  2a 4c 62            LHLD     $624c

F_M_36e7:
$36e7:  22 cc 61            SHLD     $61cc
$36ea:  21 00 00            LXI      H,$0000
$36ed:  22 e2 61            SHLD     $61e2
$36f0:  c3 7a 37            JMP      $377a

F_M_36f3:
$36f3:  2a 4c 62            LHLD     $624c
$36f6:  eb                  XCHG
$36f7:  2a 4e 62            LHLD     $624e
$36fa:  cd c6 38            CALL     $38c6
$36fd:  c2 06 37            JNZ      $3706
$3700:  21 2d 00            LXI      H,$002d
$3703:  c3 48 37            JMP      $3748

F_M_3706:
$3706:  da 0a 37            JC       $370a
$3709:  eb                  XCHG

F_M_370a:
$370a:  cd e3 28            CALL     $28e3
$370d:  eb                  XCHG
$370e:  cd ee 38            CALL     $38ee
$3711:  22 e2 61            SHLD     $61e2
$3714:  2a 4c 62            LHLD     $624c
$3717:  eb                  XCHG
$3718:  2a 4e 62            LHLD     $624e
$371b:  cd c6 38            CALL     $38c6
$371e:  2a e2 61            LHLD     $61e2
$3721:  da 34 37            JC       $3734
$3724:  3a e8 61            LDA      $61e8
$3727:  fe 04               CPI      $04
$3729:  ca 48 37            JZ       $3748
$372c:  fe 02               CPI      $02
$372e:  ca 48 37            JZ       $3748
$3731:  c3 41 37            JMP      $3741

F_M_3734:
$3734:  3a e8 61            LDA      $61e8
$3737:  fe 03               CPI      $03
$3739:  ca 48 37            JZ       $3748
$373c:  fe 01               CPI      $01
$373e:  ca 48 37            JZ       $3748

F_M_3741:
$3741:  eb                  XCHG
$3742:  21 5a 00            LXI      H,$005a
$3745:  cd bb 38            CALL     $38bb

F_M_3748:
$3748:  22 e2 61            SHLD     $61e2
$374b:  3a e2 61            LDA      $61e2
$374e:  a7                  ANA      A
$374f:  07                  RLC
$3750:  4f                  MOV      C,A
$3751:  06 00               MVI      B,$00
$3753:  21 c2 40            LXI      H,$40c2
$3756:  09                  DAD      B
$3757:  5e                  MOV      E,M
$3758:  23                  INX      H
$3759:  56                  MOV      D,M
$375a:  2a 4e 62            LHLD     $624e
$375d:  3a e8 61            LDA      $61e8
$3760:  fe 03               CPI      $03
$3762:  ca 6d 37            JZ       $376d
$3765:  fe 01               CPI      $01
$3767:  ca 6d 37            JZ       $376d
$376a:  2a 4c 62            LHLD     $624c

F_M_376d:
$376d:  cd e3 28            CALL     $28e3
$3770:  7c                  MOV      A,H
$3771:  a7                  ANA      A
$3772:  1f                  RAR
$3773:  67                  MOV      H,A
$3774:  7d                  MOV      A,L
$3775:  1f                  RAR
$3776:  6f                  MOV      L,A
$3777:  22 cc 61            SHLD     $61cc

F_M_377a:
$377a:  2a ec 61            LHLD     $61ec
$377d:  7c                  MOV      A,H
$377e:  a7                  ANA      A
$377f:  f2 91 37            JP       $3791
$3782:  e6 7f               ANI      $7f
$3784:  67                  MOV      H,A
$3785:  22 ec 61            SHLD     $61ec
$3788:  2a ca 61            LHLD     $61ca
$378b:  22 42 62            SHLD     $6242
$378e:  c3 9a 37            JMP      $379a

F_M_3791:
$3791:  2a ca 61            LHLD     $61ca
$3794:  22 42 62            SHLD     $6242
$3797:  cd e3 38            CALL     $38e3

F_M_379a:
$379a:  22 ca 61            SHLD     $61ca
$379d:  cd 16 11            CALL     $1116

F_M_37a0:
$37a0:  2a ca 61            LHLD     $61ca
$37a3:  eb                  XCHG
$37a4:  2a e2 61            LHLD     $61e2
$37a7:  19                  DAD      D
$37a8:  7c                  MOV      A,H
$37a9:  a7                  ANA      A
$37aa:  11 5a 00            LXI      D,$005a
$37ad:  f2 bd 37            JP       $37bd
$37b0:  19                  DAD      D
$37b1:  3a e8 61            LDA      $61e8
$37b4:  3d                  DCR      A
$37b5:  c2 d1 37            JNZ      $37d1
$37b8:  3e 04               MVI      A,$04
$37ba:  c3 d1 37            JMP      $37d1

F_M_37bd:
$37bd:  cd c6 38            CALL     $38c6
$37c0:  da d4 37            JC       $37d4
$37c3:  cd bb 38            CALL     $38bb
$37c6:  3a e8 61            LDA      $61e8
$37c9:  3c                  INR      A
$37ca:  fe 05               CPI      $05
$37cc:  c2 d1 37            JNZ      $37d1
$37cf:  3e 01               MVI      A,$01

F_M_37d1:
$37d1:  32 e8 61            STA      $61e8

F_M_37d4:
$37d4:  22 e2 61            SHLD     $61e2
$37d7:  21 76 41            LXI      H,$4176
$37da:  3a e2 61            LDA      $61e2
$37dd:  07                  RLC
$37de:  5f                  MOV      E,A
$37df:  16 00               MVI      D,$00
$37e1:  cd bb 38            CALL     $38bb
$37e4:  5e                  MOV      E,M
$37e5:  23                  INX      H
$37e6:  56                  MOV      D,M
$37e7:  2a cc 61            LHLD     $61cc
$37ea:  cd 57 29            CALL     $2957
$37ed:  cd cc 38            CALL     $38cc
$37f0:  22 e6 61            SHLD     $61e6
$37f3:  21 c2 40            LXI      H,$40c2
$37f6:  3a e2 61            LDA      $61e2
$37f9:  07                  RLC
$37fa:  5f                  MOV      E,A
$37fb:  16 00               MVI      D,$00
$37fd:  19                  DAD      D
$37fe:  5e                  MOV      E,M
$37ff:  23                  INX      H
$3800:  56                  MOV      D,M
$3801:  2a cc 61            LHLD     $61cc
$3804:  cd 57 29            CALL     $2957
$3807:  cd cc 38            CALL     $38cc
$380a:  22 e4 61            SHLD     $61e4
$380d:  3a e8 61            LDA      $61e8
$3810:  fe 01               CPI      $01
$3812:  c2 32 38            JNZ      $3832
$3815:  2a e6 61            LHLD     $61e6
$3818:  eb                  XCHG
$3819:  2a d8 61            LHLD     $61d8
$381c:  cd bb 38            CALL     $38bb
$381f:  22 5d 63            SHLD     $635d
$3822:  2a e4 61            LHLD     $61e4
$3825:  eb                  XCHG
$3826:  2a da 61            LHLD     $61da
$3829:  cd b1 38            CALL     $38b1
$382c:  22 5f 63            SHLD     $635f
$382f:  c3 90 38            JMP      $3890

F_M_3832:
$3832:  fe 02               CPI      $02
$3834:  c2 54 38            JNZ      $3854
$3837:  2a e4 61            LHLD     $61e4
$383a:  eb                  XCHG
$383b:  2a d8 61            LHLD     $61d8
$383e:  cd b1 38            CALL     $38b1
$3841:  22 5d 63            SHLD     $635d
$3844:  2a e6 61            LHLD     $61e6
$3847:  eb                  XCHG
$3848:  2a da 61            LHLD     $61da
$384b:  cd b1 38            CALL     $38b1
$384e:  22 5f 63            SHLD     $635f
$3851:  c3 90 38            JMP      $3890

F_M_3854:
$3854:  fe 03               CPI      $03
$3856:  c2 76 38            JNZ      $3876
$3859:  2a e6 61            LHLD     $61e6
$385c:  eb                  XCHG
$385d:  2a d8 61            LHLD     $61d8
$3860:  cd b1 38            CALL     $38b1
$3863:  22 5d 63            SHLD     $635d
$3866:  2a e4 61            LHLD     $61e4
$3869:  eb                  XCHG
$386a:  2a da 61            LHLD     $61da
$386d:  cd bb 38            CALL     $38bb
$3870:  22 5f 63            SHLD     $635f
$3873:  c3 90 38            JMP      $3890

F_M_3876:
$3876:  2a e4 61            LHLD     $61e4
$3879:  eb                  XCHG
$387a:  2a d8 61            LHLD     $61d8
$387d:  cd bb 38            CALL     $38bb
$3880:  22 5d 63            SHLD     $635d
$3883:  2a e6 61            LHLD     $61e6
$3886:  eb                  XCHG
$3887:  2a da 61            LHLD     $61da
$388a:  cd bb 38            CALL     $38bb
$388d:  22 5f 63            SHLD     $635f

F_M_3890:
$3890:  cd e0 1c            CALL     $1ce0
$3893:  2a 42 62            LHLD     $6242
$3896:  eb                  XCHG
$3897:  2a ea 61            LHLD     $61ea
$389a:  19                  DAD      D
$389b:  22 ea 61            SHLD     $61ea
$389e:  eb                  XCHG
$389f:  2a ec 61            LHLD     $61ec
$38a2:  cd c6 38            CALL     $38c6
$38a5:  ca ab 38            JZ       $38ab
$38a8:  d2 a0 37            JNC      $37a0

F_M_38ab:
$38ab:  cd 88 02            CALL     $0288
$38ae:  c3 16 11            JMP      $1116

F_M_38b1:
$38b1:  19                  DAD      D
$38b2:  7a                  MOV      A,D
$38b3:  17                  RAL
$38b4:  d2 ba 38            JNC      $38ba
$38b7:  21 ff 7f            LXI      H,$7fff

F_M_38ba:
$38ba:  c9                  RET

F_M_38bb:
$38bb:  7d                  MOV      A,L
$38bc:  93                  SUB      E
$38bd:  6f                  MOV      L,A
$38be:  7c                  MOV      A,H
$38bf:  9a                  SBB      D
$38c0:  67                  MOV      H,A
$38c1:  f0                  RP
$38c2:  21 00 00            LXI      H,$0000
$38c5:  c9                  RET

F_M_38c6:
$38c6:  7c                  MOV      A,H
$38c7:  ba                  CMP      D
$38c8:  c0                  RNZ
$38c9:  7d                  MOV      A,L
$38ca:  bb                  CMP      E
$38cb:  c9                  RET

F_M_38cc:
$38cc:  7c                  MOV      A,H
$38cd:  a7                  ANA      A
$38ce:  17                  RAL
$38cf:  7b                  MOV      A,E
$38d0:  17                  RAL
$38d1:  5f                  MOV      E,A
$38d2:  7a                  MOV      A,D
$38d3:  17                  RAL
$38d4:  57                  MOV      D,A
$38d5:  d5                  PUSH     D
$38d6:  11 aa aa            LXI      D,$aaaa
$38d9:  19                  DAD      D
$38da:  e1                  POP      H
$38db:  d2 e2 38            JNC      $38e2
$38de:  11 01 00            LXI      D,$0001
$38e1:  19                  DAD      D

F_M_38e2:
$38e2:  c9                  RET

F_M_38e3:
$38e3:  7d                  MOV      A,L
$38e4:  2f                  CMA
$38e5:  6f                  MOV      L,A
$38e6:  7c                  MOV      A,H
$38e7:  2f                  CMA
$38e8:  67                  MOV      H,A
$38e9:  01 01 00            LXI      B,$0001
$38ec:  09                  DAD      B
$38ed:  c9                  RET

F_M_38ee:
$38ee:  21 78 41            LXI      H,$4178

F_M_38f1:
$38f1:  4e                  MOV      C,M
$38f2:  23                  INX      H
$38f3:  46                  MOV      B,M
$38f4:  23                  INX      H
$38f5:  c5                  PUSH     B
$38f6:  e3                  XTHL
$38f7:  cd c6 38            CALL     $38c6
$38fa:  3a 54 62            LDA      $6254
$38fd:  ca 13 39            JZ       $3913
$3900:  d2 13 39            JNC      $3913
$3903:  e1                  POP      H
$3904:  3c                  INR      A
$3905:  32 54 62            STA      $6254
$3908:  fe 2d               CPI      $2d
$390a:  c2 f1 38            JNZ      $38f1
$390d:  21 2d 00            LXI      H,$002d
$3910:  c3 17 39            JMP      $3917

F_M_3913:
$3913:  2a 54 62            LHLD     $6254
$3916:  c1                  POP      B

F_M_3917:
$3917:  c9                  RET
$3918:  7d                  MOV      A,L
$3919:  8b                  ADC      E
$391a:  6f                  MOV      L,A
$391b:  7c                  MOV      A,H
$391c:  8a                  ADC      D
$391d:  67                  MOV      H,A
$391e:  c9                  RET

F_M_391f:
$391f:  21 00 00            LXI      H,$0000
$3922:  22 e2 61            SHLD     $61e2
$3925:  22 e0 61            SHLD     $61e0
$3928:  22 e8 61            SHLD     $61e8
$392b:  2a 4e 63            LHLD     $634e
$392e:  22 d8 61            SHLD     $61d8
$3931:  2a 50 63            LHLD     $6350
$3934:  22 da 61            SHLD     $61da
$3937:  3a ca 61            LDA      $61ca
$393a:  fe 78               CPI      $78
$393c:  ca 47 39            JZ       $3947
$393f:  da 47 39            JC       $3947
$3942:  3e 05               MVI      A,$05
$3944:  32 ca 61            STA      $61ca

F_M_3947:
$3947:  2a cc 61            LHLD     $61cc
$394a:  eb                  XCHG
$394b:  2a 4e 63            LHLD     $634e
$394e:  cd 98 3a            CALL     $3a98
$3951:  22 5d 63            SHLD     $635d
$3954:  22 dc 61            SHLD     $61dc
$3957:  2a 50 63            LHLD     $6350
$395a:  22 5f 63            SHLD     $635f
$395d:  22 de 61            SHLD     $61de
$3960:  cd 0c 11            CALL     $110c
$3963:  cd e0 1c            CALL     $1ce0
$3966:  cd 16 11            CALL     $1116
$3969:  3e 01               MVI      A,$01
$396b:  32 e8 61            STA      $61e8

F_M_396e:
$396e:  2a ca 61            LHLD     $61ca
$3971:  eb                  XCHG
$3972:  2a e2 61            LHLD     $61e2
$3975:  19                  DAD      D
$3976:  11 5a 00            LXI      D,$005a
$3979:  cd a3 3a            CALL     $3aa3
$397c:  da 8a 39            JC       $398a
$397f:  cd 98 3a            CALL     $3a98
$3982:  3a e8 61            LDA      $61e8
$3985:  c6 01               ADI      $01
$3987:  32 e8 61            STA      $61e8

F_M_398a:
$398a:  22 e2 61            SHLD     $61e2
$398d:  2a ca 61            LHLD     $61ca
$3990:  eb                  XCHG
$3991:  2a e0 61            LHLD     $61e0
$3994:  19                  DAD      D
$3995:  11 68 01            LXI      D,$0168
$3998:  cd a3 3a            CALL     $3aa3
$399b:  da b6 39            JC       $39b6
$399e:  2a dc 61            LHLD     $61dc
$39a1:  22 5d 63            SHLD     $635d
$39a4:  2a de 61            LHLD     $61de
$39a7:  22 5f 63            SHLD     $635f
$39aa:  cd 16 11            CALL     $1116
$39ad:  cd e0 1c            CALL     $1ce0
$39b0:  cd 0c 11            CALL     $110c
$39b3:  c3 7b 3a            JMP      $3a7b

F_M_39b6:
$39b6:  22 e0 61            SHLD     $61e0
$39b9:  21 76 41            LXI      H,$4176
$39bc:  3a e2 61            LDA      $61e2
$39bf:  07                  RLC
$39c0:  5f                  MOV      E,A
$39c1:  16 00               MVI      D,$00
$39c3:  cd 98 3a            CALL     $3a98
$39c6:  5e                  MOV      E,M
$39c7:  23                  INX      H
$39c8:  56                  MOV      D,M
$39c9:  2a cc 61            LHLD     $61cc
$39cc:  cd 57 29            CALL     $2957
$39cf:  cd a9 3a            CALL     $3aa9
$39d2:  22 e6 61            SHLD     $61e6
$39d5:  21 c2 40            LXI      H,$40c2
$39d8:  3a e2 61            LDA      $61e2
$39db:  07                  RLC
$39dc:  5f                  MOV      E,A
$39dd:  16 00               MVI      D,$00
$39df:  19                  DAD      D
$39e0:  5e                  MOV      E,M
$39e1:  23                  INX      H
$39e2:  56                  MOV      D,M
$39e3:  2a cc 61            LHLD     $61cc
$39e6:  cd 57 29            CALL     $2957
$39e9:  cd a9 3a            CALL     $3aa9
$39ec:  22 e4 61            SHLD     $61e4
$39ef:  3a e8 61            LDA      $61e8
$39f2:  fe 01               CPI      $01
$39f4:  c2 14 3a            JNZ      $3a14
$39f7:  2a e6 61            LHLD     $61e6
$39fa:  eb                  XCHG
$39fb:  2a d8 61            LHLD     $61d8
$39fe:  cd 98 3a            CALL     $3a98
$3a01:  22 5d 63            SHLD     $635d
$3a04:  2a e4 61            LHLD     $61e4
$3a07:  eb                  XCHG
$3a08:  2a da 61            LHLD     $61da
$3a0b:  cd 8d 3a            CALL     $3a8d
$3a0e:  22 5f 63            SHLD     $635f
$3a11:  c3 72 3a            JMP      $3a72

F_M_3a14:
$3a14:  fe 02               CPI      $02
$3a16:  c2 36 3a            JNZ      $3a36
$3a19:  2a e4 61            LHLD     $61e4
$3a1c:  eb                  XCHG
$3a1d:  2a d8 61            LHLD     $61d8
$3a20:  cd 8d 3a            CALL     $3a8d
$3a23:  22 5d 63            SHLD     $635d
$3a26:  2a e6 61            LHLD     $61e6
$3a29:  eb                  XCHG
$3a2a:  2a da 61            LHLD     $61da
$3a2d:  cd 8d 3a            CALL     $3a8d
$3a30:  22 5f 63            SHLD     $635f
$3a33:  c3 72 3a            JMP      $3a72

F_M_3a36:
$3a36:  fe 03               CPI      $03
$3a38:  c2 58 3a            JNZ      $3a58
$3a3b:  2a e6 61            LHLD     $61e6
$3a3e:  eb                  XCHG
$3a3f:  2a d8 61            LHLD     $61d8
$3a42:  cd 8d 3a            CALL     $3a8d
$3a45:  22 5d 63            SHLD     $635d
$3a48:  2a e4 61            LHLD     $61e4
$3a4b:  eb                  XCHG
$3a4c:  2a da 61            LHLD     $61da
$3a4f:  cd 98 3a            CALL     $3a98
$3a52:  22 5f 63            SHLD     $635f
$3a55:  c3 72 3a            JMP      $3a72

F_M_3a58:
$3a58:  2a e4 61            LHLD     $61e4
$3a5b:  eb                  XCHG
$3a5c:  2a d8 61            LHLD     $61d8
$3a5f:  cd 98 3a            CALL     $3a98
$3a62:  22 5d 63            SHLD     $635d
$3a65:  2a e6 61            LHLD     $61e6
$3a68:  eb                  XCHG
$3a69:  2a da 61            LHLD     $61da
$3a6c:  cd 98 3a            CALL     $3a98
$3a6f:  22 5f 63            SHLD     $635f

F_M_3a72:
$3a72:  cd 16 11            CALL     $1116
$3a75:  cd e0 1c            CALL     $1ce0
$3a78:  c3 6e 39            JMP      $396e

F_M_3a7b:
$3a7b:  2a d8 61            LHLD     $61d8
$3a7e:  22 5d 63            SHLD     $635d
$3a81:  2a da 61            LHLD     $61da
$3a84:  22 5f 63            SHLD     $635f
$3a87:  cd 0c 11            CALL     $110c
$3a8a:  c3 e0 1c            JMP      $1ce0

F_M_3a8d:
$3a8d:  19                  DAD      D
$3a8e:  7a                  MOV      A,D
$3a8f:  a7                  ANA      A
$3a90:  17                  RAL
$3a91:  d2 97 3a            JNC      $3a97
$3a94:  21 ff 7f            LXI      H,$7fff

F_M_3a97:
$3a97:  c9                  RET

F_M_3a98:
$3a98:  7d                  MOV      A,L
$3a99:  93                  SUB      E
$3a9a:  6f                  MOV      L,A
$3a9b:  7c                  MOV      A,H
$3a9c:  9a                  SBB      D
$3a9d:  67                  MOV      H,A
$3a9e:  f0                  RP
$3a9f:  21 00 00            LXI      H,$0000
$3aa2:  c9                  RET

F_M_3aa3:
$3aa3:  7c                  MOV      A,H
$3aa4:  ba                  CMP      D
$3aa5:  c0                  RNZ
$3aa6:  7d                  MOV      A,L
$3aa7:  bb                  CMP      E
$3aa8:  c9                  RET

F_M_3aa9:
$3aa9:  7c                  MOV      A,H
$3aaa:  a7                  ANA      A
$3aab:  17                  RAL
$3aac:  7b                  MOV      A,E
$3aad:  17                  RAL
$3aae:  5f                  MOV      E,A
$3aaf:  7a                  MOV      A,D
$3ab0:  17                  RAL
$3ab1:  57                  MOV      D,A
$3ab2:  d5                  PUSH     D
$3ab3:  11 aa aa            LXI      D,$aaaa
$3ab6:  19                  DAD      D
$3ab7:  e1                  POP      H
$3ab8:  d2 bf 3a            JNC      $3abf
$3abb:  11 01 00            LXI      D,$0001
$3abe:  19                  DAD      D

F_M_3abf:
$3abf:  c9                  RET

F_M_3ac0:
$3ac0:  f5                  PUSH     PSW
$3ac1:  cd 7c 02            CALL     $027c
$3ac4:  cd 8f 02            CALL     $028f
$3ac7:  f1                  POP      PSW
$3ac8:  cd d2 3a            CALL     $3ad2
$3acb:  cd 9a 02            CALL     $029a
$3ace:  cd 88 02            CALL     $0288
$3ad1:  c9                  RET

F_M_3ad2:
$3ad2:  32 87 62            STA      $6287
$3ad5:  3a 68 62            LDA      $6268
$3ad8:  32 86 62            STA      $6286
$3adb:  af                  XRA      A
$3adc:  32 68 62            STA      $6268
$3adf:  3a ec 62            LDA      $62ec
$3ae2:  e6 7f               ANI      $7f
$3ae4:  ca 1c 3b            JZ       $3b1c
$3ae7:  e6 03               ANI      $03
$3ae9:  ca f7 3a            JZ       $3af7
$3aec:  fe 01               CPI      $01
$3aee:  ca f4 3a            JZ       $3af4
$3af1:  cd eb 3b            CALL     $3beb

F_M_3af4:
$3af4:  cd fa 3b            CALL     $3bfa

F_M_3af7:
$3af7:  3a ec 62            LDA      $62ec
$3afa:  e6 7f               ANI      $7f
$3afc:  fe 14               CPI      $14
$3afe:  d0                  RNC
$3aff:  a7                  ANA      A
$3b00:  ca 1c 3b            JZ       $3b1c
$3b03:  21 08 3b            LXI      H,$3b08
$3b06:  5f                  MOV      E,A
$3b07:  16 00               MVI      D,$00
$3b09:  19                  DAD      D
$3b0a:  e9                  PCHL
$3b0b:  00                  NOP
$3b0c:  cd 06 3d            CALL     $3d06
$3b0f:  c9                  RET
$3b10:  cd 76 3d            CALL     $3d76
$3b13:  c9                  RET
$3b14:  cd 6c 3b            CALL     $3b6c
$3b17:  c9                  RET
$3b18:  cd 0d 3e            CALL     $3e0d
$3b1b:  c9                  RET

F_M_3b1c:
$3b1c:  cd 4f 3e            CALL     $3e4f
$3b1f:  3a 87 62            LDA      $6287

F_M_3b22:
$3b22:  32 87 62            STA      $6287
$3b25:  fe 20               CPI      $20
$3b27:  d2 5f 3b            JNC      $3b5f
$3b2a:  fe 03               CPI      $03
$3b2c:  ca 65 3b            JZ       $3b65
$3b2f:  cd 35 3b            CALL     $3b35
$3b32:  c3 4f 3b            JMP      $3b4f

F_M_3b35:
$3b35:  fe 08               CPI      $08
$3b37:  ca 4c 3f            JZ       $3f4c
$3b3a:  fe 0a               CPI      $0a
$3b3c:  ca 5f 3f            JZ       $3f5f
$3b3f:  fe 0d               CPI      $0d
$3b41:  ca ac 3f            JZ       $3fac
$3b44:  fe 0e               CPI      $0e
$3b46:  ca de 44            JZ       $44de
$3b49:  fe 0f               CPI      $0f
$3b4b:  ca e5 44            JZ       $44e5
$3b4e:  c9                  RET

F_M_3b4f:
$3b4f:  3a 87 62            LDA      $6287
$3b52:  21 ed 62            LXI      H,$62ed
$3b55:  be                  CMP      M
$3b56:  ca 65 3b            JZ       $3b65
$3b59:  cd 44 61            CALL     $6144
$3b5c:  c3 22 3b            JMP      $3b22

F_M_3b5f:
$3b5f:  cd 89 3e            CALL     $3e89
$3b62:  c3 4f 3b            JMP      $3b4f

F_M_3b65:
$3b65:  3a 86 62            LDA      $6286
$3b68:  32 68 62            STA      $6268
$3b6b:  c9                  RET

F_M_3b6c:
$3b6c:  cd 0c 11            CALL     $110c
$3b6f:  2a 82 62            LHLD     $6282
$3b72:  7c                  MOV      A,H
$3b73:  b5                  ORA      L
$3b74:  ca 83 3b            JZ       $3b83
$3b77:  fe 80               CPI      $80
$3b79:  ca 95 3b            JZ       $3b95
$3b7c:  06 00               MVI      B,$00
$3b7e:  0e 10               MVI      C,$10
$3b80:  cd 9b 3b            CALL     $3b9b

F_M_3b83:
$3b83:  2a 84 62            LHLD     $6284
$3b86:  7c                  MOV      A,H
$3b87:  b5                  ORA      L
$3b88:  c8                  RZ
$3b89:  fe 80               CPI      $80
$3b8b:  ca 5f 3f            JZ       $3f5f
$3b8e:  06 1f               MVI      B,$1f
$3b90:  0e 00               MVI      C,$00
$3b92:  c3 9b 3b            JMP      $3b9b

F_M_3b95:
$3b95:  cd ac 3f            CALL     $3fac
$3b98:  c3 83 3b            JMP      $3b83

F_M_3b9b:
$3b9b:  e5                  PUSH     H
$3b9c:  cd 99 3f            CALL     $3f99
$3b9f:  cd e2 3e            CALL     $3ee2
$3ba2:  cd 99 3f            CALL     $3f99
$3ba5:  c1                  POP      B
$3ba6:  78                  MOV      A,B
$3ba7:  a7                  ANA      A
$3ba8:  f5                  PUSH     PSW
$3ba9:  f2 af 3b            JP       $3baf
$3bac:  e6 7f               ANI      $7f
$3bae:  47                  MOV      B,A

F_M_3baf:
$3baf:  2a 92 62            LHLD     $6292
$3bb2:  f1                  POP      PSW
$3bb3:  f5                  PUSH     PSW
$3bb4:  fc db 28            CM       $28db
$3bb7:  eb                  XCHG
$3bb8:  2a 94 62            LHLD     $6294
$3bbb:  f1                  POP      PSW
$3bbc:  fc db 28            CM       $28db
$3bbf:  e5                  PUSH     H
$3bc0:  c5                  PUSH     B
$3bc1:  2a 4e 63            LHLD     $634e

F_M_3bc4:
$3bc4:  cd bb 28            CALL     $28bb
$3bc7:  0b                  DCX      B
$3bc8:  78                  MOV      A,B
$3bc9:  b1                  ORA      C
$3bca:  c2 c4 3b            JNZ      $3bc4
$3bcd:  22 5d 63            SHLD     $635d
$3bd0:  22 a0 62            SHLD     $62a0
$3bd3:  c1                  POP      B
$3bd4:  d1                  POP      D
$3bd5:  2a 50 63            LHLD     $6350

F_M_3bd8:
$3bd8:  cd bb 28            CALL     $28bb
$3bdb:  0b                  DCX      B
$3bdc:  78                  MOV      A,B
$3bdd:  b1                  ORA      C
$3bde:  c2 d8 3b            JNZ      $3bd8
$3be1:  22 5f 63            SHLD     $635f
$3be4:  22 a2 62            SHLD     $62a2
$3be7:  cd e0 1c            CALL     $1ce0
$3bea:  c9                  RET

F_M_3beb:
$3beb:  cd 09 3c            CALL     $3c09
$3bee:  cd 22 3c            CALL     $3c22
$3bf1:  3a ec 62            LDA      $62ec
$3bf4:  e6 fc               ANI      $fc
$3bf6:  32 ec 62            STA      $62ec
$3bf9:  c9                  RET

F_M_3bfa:
$3bfa:  cd 3b 3c            CALL     $3c3b
$3bfd:  cd a4 3c            CALL     $3ca4
$3c00:  3a ec 62            LDA      $62ec
$3c03:  e6 fc               ANI      $fc
$3c05:  32 ec 62            STA      $62ec
$3c08:  c9                  RET

F_M_3c09:
$3c09:  21 c4 62            LXI      H,$62c4
$3c0c:  11 d8 62            LXI      D,$62d8
$3c0f:  01 a4 62            LXI      B,$62a4
$3c12:  cd f7 3f            CALL     $3ff7
$3c15:  21 a4 62            LXI      H,$62a4
$3c18:  11 ec 44            LXI      D,$44ec
$3c1b:  01 b4 62            LXI      B,$62b4
$3c1e:  cd f7 3f            CALL     $3ff7
$3c21:  c9                  RET

F_M_3c22:
$3c22:  21 c8 62            LXI      H,$62c8
$3c25:  11 d4 62            LXI      D,$62d4
$3c28:  01 ac 62            LXI      B,$62ac
$3c2b:  cd f7 3f            CALL     $3ff7
$3c2e:  21 ac 62            LXI      H,$62ac
$3c31:  11 ec 44            LXI      D,$44ec
$3c34:  01 bc 62            LXI      B,$62bc
$3c37:  cd f7 3f            CALL     $3ff7
$3c3a:  c9                  RET

F_M_3c3b:
$3c3b:  21 c4 62            LXI      H,$62c4
$3c3e:  11 d4 62            LXI      D,$62d4
$3c41:  01 e8 62            LXI      B,$62e8
$3c44:  cd f7 3f            CALL     $3ff7
$3c47:  21 35 63            LXI      H,$6335
$3c4a:  11 d8 62            LXI      D,$62d8
$3c4d:  01 a8 62            LXI      B,$62a8
$3c50:  c5                  PUSH     B
$3c51:  c5                  PUSH     B
$3c52:  c5                  PUSH     B
$3c53:  cd f7 3f            CALL     $3ff7
$3c56:  2a aa 62            LHLD     $62aa
$3c59:  eb                  XCHG
$3c5a:  2a a8 62            LHLD     $62a8
$3c5d:  cd df 3f            CALL     $3fdf
$3c60:  d5                  PUSH     D
$3c61:  e5                  PUSH     H
$3c62:  2a d6 62            LHLD     $62d6
$3c65:  eb                  XCHG
$3c66:  2a d4 62            LHLD     $62d4
$3c69:  7a                  MOV      A,D
$3c6a:  a7                  ANA      A
$3c6b:  f5                  PUSH     PSW
$3c6c:  e6 7f               ANI      $7f
$3c6e:  57                  MOV      D,A
$3c6f:  f1                  POP      PSW
$3c70:  f4 e5 3f            CP       $3fe5
$3c73:  c1                  POP      B
$3c74:  09                  DAD      B
$3c75:  d2 79 3c            JNC      $3c79
$3c78:  13                  INX      D

F_M_3c79:
$3c79:  e3                  XTHL
$3c7a:  19                  DAD      D
$3c7b:  eb                  XCHG
$3c7c:  e1                  POP      H
$3c7d:  7a                  MOV      A,D
$3c7e:  e6 80               ANI      $80
$3c80:  f5                  PUSH     PSW
$3c81:  fc e5 3f            CM       $3fe5
$3c84:  f1                  POP      PSW
$3c85:  f2 8a 3c            JP       $3c8a
$3c88:  b2                  ORA      D
$3c89:  57                  MOV      D,A

F_M_3c8a:
$3c8a:  22 a8 62            SHLD     $62a8
$3c8d:  eb                  XCHG
$3c8e:  22 aa 62            SHLD     $62aa
$3c91:  e1                  POP      H
$3c92:  c1                  POP      B
$3c93:  11 c4 62            LXI      D,$62c4
$3c96:  cd f7 3f            CALL     $3ff7
$3c99:  e1                  POP      H
$3c9a:  11 f0 44            LXI      D,$44f0
$3c9d:  01 b8 62            LXI      B,$62b8
$3ca0:  cd f7 3f            CALL     $3ff7
$3ca3:  c9                  RET

F_M_3ca4:
$3ca4:  21 c8 62            LXI      H,$62c8
$3ca7:  11 d8 62            LXI      D,$62d8
$3caa:  01 e4 62            LXI      B,$62e4
$3cad:  cd f7 3f            CALL     $3ff7
$3cb0:  21 35 63            LXI      H,$6335
$3cb3:  11 d4 62            LXI      D,$62d4
$3cb6:  01 b0 62            LXI      B,$62b0
$3cb9:  c5                  PUSH     B
$3cba:  c5                  PUSH     B
$3cbb:  c5                  PUSH     B
$3cbc:  cd f7 3f            CALL     $3ff7
$3cbf:  2a b2 62            LHLD     $62b2
$3cc2:  eb                  XCHG
$3cc3:  2a b0 62            LHLD     $62b0
$3cc6:  cd df 3f            CALL     $3fdf
$3cc9:  d5                  PUSH     D
$3cca:  e5                  PUSH     H
$3ccb:  2a da 62            LHLD     $62da
$3cce:  eb                  XCHG
$3ccf:  2a d8 62            LHLD     $62d8
$3cd2:  cd df 3f            CALL     $3fdf
$3cd5:  c1                  POP      B
$3cd6:  09                  DAD      B
$3cd7:  d2 db 3c            JNC      $3cdb
$3cda:  13                  INX      D

F_M_3cdb:
$3cdb:  e3                  XTHL
$3cdc:  19                  DAD      D
$3cdd:  eb                  XCHG
$3cde:  e1                  POP      H
$3cdf:  7a                  MOV      A,D
$3ce0:  e6 80               ANI      $80
$3ce2:  f5                  PUSH     PSW
$3ce3:  fc e5 3f            CM       $3fe5
$3ce6:  f1                  POP      PSW
$3ce7:  f2 ec 3c            JP       $3cec
$3cea:  b2                  ORA      D
$3ceb:  57                  MOV      D,A

F_M_3cec:
$3cec:  22 b0 62            SHLD     $62b0
$3cef:  eb                  XCHG
$3cf0:  22 b2 62            SHLD     $62b2
$3cf3:  e1                  POP      H
$3cf4:  c1                  POP      B
$3cf5:  11 c8 62            LXI      D,$62c8
$3cf8:  cd f7 3f            CALL     $3ff7
$3cfb:  e1                  POP      H
$3cfc:  11 f0 44            LXI      D,$44f0
$3cff:  01 c0 62            LXI      B,$62c0
$3d02:  cd f7 3f            CALL     $3ff7
$3d05:  c9                  RET

F_M_3d06:
$3d06:  cd 61 3d            CALL     $3d61
$3d09:  06 8e               MVI      B,$8e
$3d0b:  0e 00               MVI      C,$00
$3d0d:  cd e2 3e            CALL     $3ee2
$3d10:  2a 4e 63            LHLD     $634e
$3d13:  22 9c 62            SHLD     $629c
$3d16:  22 a0 62            SHLD     $62a0
$3d19:  eb                  XCHG
$3d1a:  2a 92 62            LHLD     $6292
$3d1d:  cd bb 28            CALL     $28bb
$3d20:  22 cc 62            SHLD     $62cc
$3d23:  2a 50 63            LHLD     $6350
$3d26:  22 9e 62            SHLD     $629e
$3d29:  22 a2 62            SHLD     $62a2
$3d2c:  eb                  XCHG
$3d2d:  2a 94 62            LHLD     $6294
$3d30:  cd bb 28            CALL     $28bb
$3d33:  22 ce 62            SHLD     $62ce
$3d36:  06 0e               MVI      B,$0e
$3d38:  0e 40               MVI      C,$40
$3d3a:  cd e2 3e            CALL     $3ee2
$3d3d:  2a cc 62            LHLD     $62cc
$3d40:  eb                  XCHG
$3d41:  2a 92 62            LHLD     $6292
$3d44:  cd bb 28            CALL     $28bb
$3d47:  22 d0 62            SHLD     $62d0
$3d4a:  2a ce 62            LHLD     $62ce
$3d4d:  eb                  XCHG
$3d4e:  2a 94 62            LHLD     $6294
$3d51:  cd bb 28            CALL     $28bb
$3d54:  22 d2 62            SHLD     $62d2
$3d57:  21 ee 62            LXI      H,$62ee
$3d5a:  cd a5 3d            CALL     $3da5
$3d5d:  cd 61 3d            CALL     $3d61
$3d60:  c9                  RET

F_M_3d61:
$3d61:  06 10               MVI      B,$10
$3d63:  21 a4 62            LXI      H,$62a4
$3d66:  11 b4 62            LXI      D,$62b4

F_M_3d69:
$3d69:  7e                  MOV      A,M
$3d6a:  eb                  XCHG
$3d6b:  4e                  MOV      C,M
$3d6c:  77                  MOV      M,A
$3d6d:  eb                  XCHG
$3d6e:  71                  MOV      M,C
$3d6f:  23                  INX      H
$3d70:  13                  INX      D
$3d71:  05                  DCR      B
$3d72:  c2 69 3d            JNZ      $3d69
$3d75:  c9                  RET

F_M_3d76:
$3d76:  2a 4e 63            LHLD     $634e
$3d79:  22 cc 62            SHLD     $62cc
$3d7c:  22 d0 62            SHLD     $62d0
$3d7f:  2a 50 63            LHLD     $6350
$3d82:  22 ce 62            SHLD     $62ce
$3d85:  22 d2 62            SHLD     $62d2
$3d88:  3a 87 62            LDA      $6287
$3d8b:  cd 62 3e            CALL     $3e62
$3d8e:  23                  INX      H

F_M_3d8f:
$3d8f:  23                  INX      H
$3d90:  7e                  MOV      A,M
$3d91:  fe c1               CPI      $c1
$3d93:  ca d6 3d            JZ       $3dd6
$3d96:  47                  MOV      B,A
$3d97:  23                  INX      H
$3d98:  4e                  MOV      C,M
$3d99:  e5                  PUSH     H
$3d9a:  cd e2 3e            CALL     $3ee2
$3d9d:  cd ef 3d            CALL     $3def

F_M_3da0:
$3da0:  cd 16 11            CALL     $1116

F_M_3da3:
$3da3:  e1                  POP      H
$3da4:  23                  INX      H

F_M_3da5:
$3da5:  7e                  MOV      A,M
$3da6:  fe 40               CPI      $40
$3da8:  e5                  PUSH     H
$3da9:  ca a0 3d            JZ       $3da0
$3dac:  fe c0               CPI      $c0
$3dae:  ca cf 3d            JZ       $3dcf
$3db1:  d2 d5 3d            JNC      $3dd5
$3db4:  47                  MOV      B,A
$3db5:  23                  INX      H
$3db6:  4e                  MOV      C,M
$3db7:  e3                  XTHL
$3db8:  79                  MOV      A,C
$3db9:  fe 40               CPI      $40
$3dbb:  ca a0 3d            JZ       $3da0
$3dbe:  fe c0               CPI      $c0
$3dc0:  ca cf 3d            JZ       $3dcf
$3dc3:  d2 d5 3d            JNC      $3dd5
$3dc6:  cd e2 3e            CALL     $3ee2
$3dc9:  cd ef 3d            CALL     $3def
$3dcc:  c3 a3 3d            JMP      $3da3

F_M_3dcf:
$3dcf:  cd 0c 11            CALL     $110c
$3dd2:  c3 a3 3d            JMP      $3da3

F_M_3dd5:
$3dd5:  e1                  POP      H

F_M_3dd6:
$3dd6:  2a d0 62            LHLD     $62d0
$3dd9:  22 5d 63            SHLD     $635d
$3ddc:  22 9c 62            SHLD     $629c
$3ddf:  2a d2 62            LHLD     $62d2
$3de2:  22 5f 63            SHLD     $635f
$3de5:  22 9e 62            SHLD     $629e
$3de8:  cd 0c 11            CALL     $110c
$3deb:  cd e0 1c            CALL     $1ce0
$3dee:  c9                  RET

F_M_3def:
$3def:  2a cc 62            LHLD     $62cc
$3df2:  eb                  XCHG
$3df3:  2a 92 62            LHLD     $6292
$3df6:  cd bb 28            CALL     $28bb
$3df9:  22 5d 63            SHLD     $635d
$3dfc:  2a ce 62            LHLD     $62ce
$3dff:  eb                  XCHG
$3e00:  2a 94 62            LHLD     $6294
$3e03:  cd bb 28            CALL     $28bb
$3e06:  22 5f 63            SHLD     $635f
$3e09:  cd e0 1c            CALL     $1ce0
$3e0c:  c9                  RET

F_M_3e0d:
$3e0d:  3a 31 63            LDA      $6331
$3e10:  3d                  DCR      A
$3e11:  3d                  DCR      A
$3e12:  fe 12               CPI      $12
$3e14:  d2 4f 3e            JNC      $3e4f
$3e17:  21 f4 44            LXI      H,$44f4
$3e1a:  cd 78 3e            CALL     $3e78
$3e1d:  45                  MOV      B,L
$3e1e:  4c                  MOV      C,H
$3e1f:  cd e2 3e            CALL     $3ee2
$3e22:  2a 4e 63            LHLD     $634e
$3e25:  eb                  XCHG
$3e26:  2a 92 62            LHLD     $6292
$3e29:  cd bb 28            CALL     $28bb
$3e2c:  22 9c 62            SHLD     $629c
$3e2f:  22 a0 62            SHLD     $62a0
$3e32:  22 5d 63            SHLD     $635d
$3e35:  2a 50 63            LHLD     $6350
$3e38:  eb                  XCHG
$3e39:  2a 94 62            LHLD     $6294
$3e3c:  cd bb 28            CALL     $28bb
$3e3f:  22 9e 62            SHLD     $629e
$3e42:  22 a2 62            SHLD     $62a2
$3e45:  22 5f 63            SHLD     $635f
$3e48:  cd 0c 11            CALL     $110c
$3e4b:  cd e0 1c            CALL     $1ce0
$3e4e:  c9                  RET

F_M_3e4f:
$3e4f:  2a 4e 63            LHLD     $634e
$3e52:  22 9c 62            SHLD     $629c
$3e55:  22 a0 62            SHLD     $62a0
$3e58:  2a 50 63            LHLD     $6350
$3e5b:  22 9e 62            SHLD     $629e
$3e5e:  22 a2 62            SHLD     $62a2
$3e61:  c9                  RET

F_M_3e62:
$3e62:  2a 96 62            LHLD     $6296
$3e65:  5f                  MOV      E,A
$3e66:  16 00               MVI      D,$00
$3e68:  19                  DAD      D
$3e69:  5e                  MOV      E,M
$3e6a:  16 00               MVI      D,$00
$3e6c:  eb                  XCHG
$3e6d:  29                  DAD      H
$3e6e:  11 24 45            LXI      D,$4524
$3e71:  19                  DAD      D
$3e72:  5e                  MOV      E,M
$3e73:  23                  INX      H
$3e74:  56                  MOV      D,M
$3e75:  eb                  XCHG
$3e76:  7e                  MOV      A,M
$3e77:  c9                  RET

F_M_3e78:
$3e78:  87                  ADD      A
$3e79:  16 00               MVI      D,$00
$3e7b:  5f                  MOV      E,A
$3e7c:  19                  DAD      D
$3e7d:  5e                  MOV      E,M
$3e7e:  23                  INX      H
$3e7f:  56                  MOV      D,M
$3e80:  eb                  XCHG
$3e81:  7e                  MOV      A,M
$3e82:  c9                  RET

F_M_3e83:
$3e83:  21 18 45            LXI      H,$4518
$3e86:  c3 78 3e            JMP      $3e78

F_M_3e89:
$3e89:  2a 4e 63            LHLD     $634e
$3e8c:  22 9c 62            SHLD     $629c
$3e8f:  2a 50 63            LHLD     $6350
$3e92:  22 9e 62            SHLD     $629e
$3e95:  cd 62 3e            CALL     $3e62
$3e98:  ee 80               XRI      $80
$3e9a:  47                  MOV      B,A
$3e9b:  23                  INX      H
$3e9c:  4e                  MOV      C,M
$3e9d:  e5                  PUSH     H
$3e9e:  c5                  PUSH     B
$3e9f:  cd e2 3e            CALL     $3ee2
$3ea2:  2a 92 62            LHLD     $6292
$3ea5:  eb                  XCHG
$3ea6:  2a 4e 63            LHLD     $634e
$3ea9:  cd bb 28            CALL     $28bb
$3eac:  22 cc 62            SHLD     $62cc
$3eaf:  2a 94 62            LHLD     $6294
$3eb2:  eb                  XCHG
$3eb3:  2a 50 63            LHLD     $6350
$3eb6:  cd bb 28            CALL     $28bb
$3eb9:  22 ce 62            SHLD     $62ce
$3ebc:  c1                  POP      B
$3ebd:  78                  MOV      A,B
$3ebe:  ee 80               XRI      $80
$3ec0:  47                  MOV      B,A
$3ec1:  cd e2 3e            CALL     $3ee2
$3ec4:  2a ce 62            LHLD     $62ce
$3ec7:  eb                  XCHG
$3ec8:  2a 94 62            LHLD     $6294
$3ecb:  cd bb 28            CALL     $28bb
$3ece:  22 d2 62            SHLD     $62d2
$3ed1:  2a cc 62            LHLD     $62cc
$3ed4:  eb                  XCHG
$3ed5:  2a 92 62            LHLD     $6292
$3ed8:  cd bb 28            CALL     $28bb
$3edb:  22 d0 62            SHLD     $62d0
$3ede:  e1                  POP      H
$3edf:  c3 8f 3d            JMP      $3d8f

F_M_3ee2:
$3ee2:  c5                  PUSH     B
$3ee3:  c5                  PUSH     B
$3ee4:  79                  MOV      A,C
$3ee5:  2a a6 62            LHLD     $62a6
$3ee8:  eb                  XCHG
$3ee9:  2a a4 62            LHLD     $62a4
$3eec:  cd 4d 40            CALL     $404d
$3eef:  c1                  POP      B
$3ef0:  d5                  PUSH     D
$3ef1:  e5                  PUSH     H
$3ef2:  78                  MOV      A,B
$3ef3:  2a aa 62            LHLD     $62aa
$3ef6:  eb                  XCHG
$3ef7:  2a a8 62            LHLD     $62a8
$3efa:  cd 4d 40            CALL     $404d
$3efd:  eb                  XCHG
$3efe:  e3                  XTHL
$3eff:  19                  DAD      D
$3f00:  d1                  POP      D
$3f01:  e3                  XTHL
$3f02:  dc 41 3f            CC       $3f41
$3f05:  c1                  POP      B
$3f06:  78                  MOV      A,B
$3f07:  a7                  ANA      A
$3f08:  fc 41 3f            CM       $3f41
$3f0b:  cd bb 28            CALL     $28bb
$3f0e:  22 92 62            SHLD     $6292
$3f11:  c1                  POP      B
$3f12:  c5                  PUSH     B
$3f13:  79                  MOV      A,C
$3f14:  2a ae 62            LHLD     $62ae
$3f17:  eb                  XCHG
$3f18:  2a ac 62            LHLD     $62ac
$3f1b:  cd 4d 40            CALL     $404d
$3f1e:  c1                  POP      B
$3f1f:  d5                  PUSH     D
$3f20:  e5                  PUSH     H
$3f21:  78                  MOV      A,B
$3f22:  2a b2 62            LHLD     $62b2
$3f25:  eb                  XCHG
$3f26:  2a b0 62            LHLD     $62b0
$3f29:  cd 4d 40            CALL     $404d
$3f2c:  eb                  XCHG
$3f2d:  e3                  XTHL
$3f2e:  19                  DAD      D
$3f2f:  d1                  POP      D
$3f30:  e3                  XTHL
$3f31:  dc 41 3f            CC       $3f41
$3f34:  c1                  POP      B
$3f35:  78                  MOV      A,B
$3f36:  a7                  ANA      A
$3f37:  fc 41 3f            CM       $3f41
$3f3a:  cd bb 28            CALL     $28bb
$3f3d:  22 94 62            SHLD     $6294
$3f40:  c9                  RET

F_M_3f41:
$3f41:  7c                  MOV      A,H
$3f42:  a7                  ANA      A
$3f43:  23                  INX      H
$3f44:  f8                  RM
$3f45:  7c                  MOV      A,H
$3f46:  a7                  ANA      A
$3f47:  f0                  RP
$3f48:  21 ff 7f            LXI      H,$7fff
$3f4b:  c9                  RET

F_M_3f4c:
$3f4c:  2a 9c 62            LHLD     $629c
$3f4f:  22 5d 63            SHLD     $635d
$3f52:  2a 9e 62            LHLD     $629e
$3f55:  22 5f 63            SHLD     $635f
$3f58:  cd 0c 11            CALL     $110c
$3f5b:  cd e0 1c            CALL     $1ce0
$3f5e:  c9                  RET

F_M_3f5f:
$3f5f:  cd 99 3f            CALL     $3f99
$3f62:  06 9f               MVI      B,$9f
$3f64:  0e 00               MVI      C,$00
$3f66:  cd e2 3e            CALL     $3ee2
$3f69:  2a 4e 63            LHLD     $634e
$3f6c:  eb                  XCHG
$3f6d:  2a 92 62            LHLD     $6292
$3f70:  cd bb 28            CALL     $28bb
$3f73:  22 5d 63            SHLD     $635d
$3f76:  22 a0 62            SHLD     $62a0
$3f79:  22 9c 62            SHLD     $629c
$3f7c:  2a 50 63            LHLD     $6350
$3f7f:  eb                  XCHG
$3f80:  2a 94 62            LHLD     $6294
$3f83:  cd bb 28            CALL     $28bb
$3f86:  22 5f 63            SHLD     $635f
$3f89:  22 9e 62            SHLD     $629e
$3f8c:  22 a2 62            SHLD     $62a2
$3f8f:  cd 0c 11            CALL     $110c
$3f92:  cd e0 1c            CALL     $1ce0
$3f95:  cd 99 3f            CALL     $3f99
$3f98:  c9                  RET

F_M_3f99:
$3f99:  21 a8 62            LXI      H,$62a8
$3f9c:  11 e8 62            LXI      D,$62e8
$3f9f:  cd 31 2c            CALL     $2c31
$3fa2:  21 b0 62            LXI      H,$62b0
$3fa5:  11 e4 62            LXI      D,$62e4
$3fa8:  cd 31 2c            CALL     $2c31
$3fab:  c9                  RET

F_M_3fac:
$3fac:  2a a0 62            LHLD     $62a0
$3faf:  22 5d 63            SHLD     $635d
$3fb2:  2a a2 62            LHLD     $62a2
$3fb5:  22 5f 63            SHLD     $635f
$3fb8:  cd 0c 11            CALL     $110c
$3fbb:  cd e0 1c            CALL     $1ce0
$3fbe:  c9                  RET

F_M_3fbf:
$3fbf:  e5                  PUSH     H
$3fc0:  c5                  PUSH     B
$3fc1:  eb                  XCHG
$3fc2:  50                  MOV      D,B
$3fc3:  59                  MOV      E,C
$3fc4:  cd 60 28            CALL     $2860
$3fc7:  c1                  POP      B
$3fc8:  eb                  XCHG
$3fc9:  e3                  XTHL
$3fca:  d5                  PUSH     D
$3fcb:  78                  MOV      A,B
$3fcc:  e6 7f               ANI      $7f
$3fce:  57                  MOV      D,A
$3fcf:  59                  MOV      E,C
$3fd0:  cd e3 28            CALL     $28e3
$3fd3:  7c                  MOV      A,H
$3fd4:  a7                  ANA      A
$3fd5:  f2 d9 3f            JP       $3fd9
$3fd8:  13                  INX      D

F_M_3fd9:
$3fd9:  e1                  POP      H
$3fda:  19                  DAD      D
$3fdb:  d1                  POP      D
$3fdc:  d0                  RNC
$3fdd:  13                  INX      D
$3fde:  c9                  RET

F_M_3fdf:
$3fdf:  7a                  MOV      A,D
$3fe0:  a7                  ANA      A
$3fe1:  f0                  RP
$3fe2:  e6 7f               ANI      $7f
$3fe4:  57                  MOV      D,A

F_M_3fe5:
$3fe5:  7c                  MOV      A,H
$3fe6:  2f                  CMA
$3fe7:  67                  MOV      H,A
$3fe8:  7a                  MOV      A,D
$3fe9:  2f                  CMA
$3fea:  57                  MOV      D,A
$3feb:  7d                  MOV      A,L
$3fec:  2f                  CMA
$3fed:  6f                  MOV      L,A
$3fee:  7b                  MOV      A,E
$3fef:  2f                  CMA
$3ff0:  5f                  MOV      E,A
$3ff1:  23                  INX      H
$3ff2:  7c                  MOV      A,H
$3ff3:  b5                  ORA      L
$3ff4:  c0                  RNZ
$3ff5:  13                  INX      D
$3ff6:  c9                  RET

F_M_3ff7:
$3ff7:  c5                  PUSH     B
$3ff8:  cd 91 2a            CALL     $2a91
$3ffb:  44                  MOV      B,H
$3ffc:  4d                  MOV      C,L
$3ffd:  c3 06 40            JMP      $4006
$4000:  c5           DB  $c5
$4001:  cd           DB  $cd
$4002:  f1           DB  $f1
$4003:  29           DB  $29
$4004:  44           DB  $44
$4005:  4d           DB  $4d

F_P_4006:
$4006:  e1                  POP      H
$4007:  71                  MOV      M,C
$4008:  23                  INX      H
$4009:  70                  MOV      M,B
$400a:  23                  INX      H
$400b:  73                  MOV      M,E
$400c:  23                  INX      H
$400d:  72                  MOV      M,D
$400e:  60                  MOV      H,B
$400f:  69                  MOV      L,C

F_P_4010:
$4010:  c9                  RET

F_P_4011:
$4011:  eb                  XCHG
$4012:  21 78 41            LXI      H,$4178
$4015:  06 00               MVI      B,$00

F_P_4017:
$4017:  23                  INX      H
$4018:  7e                  MOV      A,M
$4019:  ba                  CMP      D
$401a:  d2 22 40            JNC      $4022
$401d:  23                  INX      H
$401e:  04                  INR      B
$401f:  c3 17 40            JMP      $4017

F_P_4022:
$4022:  c0                  RNZ
$4023:  2b                  DCX      H
$4024:  7e                  MOV      A,M
$4025:  bb                  CMP      E
$4026:  d0                  RNC
$4027:  23                  INX      H
$4028:  04                  INR      B
$4029:  c3 17 40            JMP      $4017

F_P_402c:
$402c:  21 c2 40            LXI      H,$40c2
$402f:  e5                  PUSH     H
$4030:  78                  MOV      A,B
$4031:  87                  ADD      A
$4032:  4f                  MOV      C,A
$4033:  06 00               MVI      B,$00
$4035:  09                  DAD      B
$4036:  5e                  MOV      E,M
$4037:  23                  INX      H
$4038:  56                  MOV      D,M
$4039:  eb                  XCHG
$403a:  29                  DAD      H
$403b:  22 a3 61            SHLD     $61a3
$403e:  e1                  POP      H
$403f:  3e b4               MVI      A,$b4
$4041:  91                  SUB      C
$4042:  4f                  MOV      C,A
$4043:  09                  DAD      B
$4044:  5e                  MOV      E,M
$4045:  23                  INX      H
$4046:  56                  MOV      D,M
$4047:  eb                  XCHG
$4048:  29                  DAD      H
$4049:  22 a7 61            SHLD     $61a7
$404c:  c9                  RET

F_P_404d:
$404d:  47                  MOV      B,A
$404e:  aa                  XRA      D
$404f:  f5                  PUSH     PSW
$4050:  7a                  MOV      A,D
$4051:  e6 7f               ANI      $7f
$4053:  57                  MOV      D,A
$4054:  d5                  PUSH     D
$4055:  78                  MOV      A,B
$4056:  e6 7f               ANI      $7f
$4058:  f5                  PUSH     PSW
$4059:  cd 70 29            CALL     $2970
$405c:  06 00               MVI      B,$00
$405e:  4f                  MOV      C,A
$405f:  f1                  POP      PSW
$4060:  e3                  XTHL
$4061:  c5                  PUSH     B
$4062:  cd 70 29            CALL     $2970
$4065:  c1                  POP      B
$4066:  09                  DAD      B
$4067:  da 7a 40            JC       $407a
$406a:  a7                  ANA      A
$406b:  c2 7a 40            JNZ      $407a
$406e:  7c                  MOV      A,H
$406f:  a7                  ANA      A
$4070:  fa 7a 40            JM       $407a
$4073:  eb                  XCHG
$4074:  e1                  POP      H

F_P_4075:
$4075:  f1                  POP      PSW
$4076:  fc e5 3f            CM       $3fe5
$4079:  c9                  RET

F_P_407a:
$407a:  11 ff 7f            LXI      D,$7fff
$407d:  e1                  POP      H
$407e:  21 00 00            LXI      H,$0000
$4081:  c3 75 40            JMP      $4075

F_P_4084:
$4084:  fe 05               CPI      $05
$4086:  da 8b 40            JC       $408b
$4089:  3e 01               MVI      A,$01

F_P_408b:
$408b:  87                  ADD      A
$408c:  5f                  MOV      E,A
$408d:  16 00               MVI      D,$00
$408f:  19                  DAD      D
$4090:  5e                  MOV      E,M
$4091:  23                  INX      H
$4092:  56                  MOV      D,M
$4093:  c9                  RET

F_P_4094:
$4094:  cd bc 44            CALL     $44bc
$4097:  cd e5 44            CALL     $44e5
$409a:  21 00 00            LXI      H,$0000
$409d:  22 8e 62            SHLD     $628e
$40a0:  22 8a 62            SHLD     $628a
$40a3:  21 00 80            LXI      H,$8000
$40a6:  22 8c 62            SHLD     $628c
$40a9:  21 cd 4c            LXI      H,$4ccd
$40ac:  22 88 62            SHLD     $6288
$40af:  cd 23 43            CALL     $4323
$40b2:  21 01 00            LXI      H,$0001
$40b5:  22 88 62            SHLD     $6288
$40b8:  21 00 00            LXI      H,$0000
$40bb:  22 8c 62            SHLD     $628c
$40be:  cd 5f 43            CALL     $435f
$40c1:  c9                  RET
$40c2:  00                  NOP
$40c3:  00                  NOP
$40c4:  3c                  INR      A
$40c5:  02                  STAX     B
$40c6:  78                  MOV      A,B
$40c7:  04                  INR      B
$40c8:  b3                  ORA      E
$40c9:  06 ee               MVI      B,$ee
$40cb:  08                  NOP
$40cc:  28                  NOP
$40cd:  0b                  DCX      B
$40ce:  61                  MOV      H,C
$40cf:  0d                  DCR      C
$40d0:  99                  SBB      C
$40d1:  0f                  RRC
$40d2:  d0                  RNC
$40d3:  11 06 14            LXI      D,$1406
$40d6:  3a 16 6c            LDA      $6c16
$40d9:  18                  NOP
$40da:  9d                  SBB      L
$40db:  1a                  LDAX     D
$40dc:  cb 1c f7            JMP      $f71c
$40df:  1e           DB  $1e
$40e0:  21           DB  $21
$40e1:  21           DB  $21
$40e2:  48           DB  $48
$40e3:  23           DB  $23
$40e4:  6c           DB  $6c
$40e5:  25           DB  $25
$40e6:  8e           DB  $8e
$40e7:  27           DB  $27
$40e8:  ac           DB  $ac
$40e9:  29           DB  $29
$40ea:  c7           DB  $c7
$40eb:  2b           DB  $2b
$40ec:  df           DB  $df
$40ed:  2d           DB  $2d
$40ee:  f3           DB  $f3
$40ef:  2f           DB  $2f
$40f0:  03           DB  $03
$40f1:  32           DB  $32
$40f2:  10           DB  $10
$40f3:  34           DB  $34
$40f4:  18           DB  $18
$40f5:  36           DB  $36
$40f6:  1c           DB  $1c
$40f7:  38           DB  $38
$40f8:  1c           DB  $1c
$40f9:  3a           DB  $3a
$40fa:  17           DB  $17
$40fb:  3c           DB  $3c
$40fc:  0e           DB  $0e
$40fd:  3e           DB  $3e
$40fe:  ff           DB  $ff
$40ff:  3f           DB  $3f
$4100:  ec           DB  $ec
$4101:  41           DB  $41
$4102:  d4           DB  $d4
$4103:  43           DB  $43
$4104:  b6           DB  $b6
$4105:  45           DB  $45
$4106:  93           DB  $93
$4107:  47           DB  $47
$4108:  6a           DB  $6a
$4109:  49           DB  $49
$410a:  3c           DB  $3c
$410b:  4b           DB  $4b
$410c:  08           DB  $08
$410d:  4d           DB  $4d
$410e:  cd           DB  $cd
$410f:  4e           DB  $4e
$4110:  8d           DB  $8d
$4111:  50           DB  $50
$4112:  46           DB  $46
$4113:  52           DB  $52
$4114:  f9           DB  $f9
$4115:  53           DB  $53
$4116:  a5           DB  $a5
$4117:  55           DB  $55
$4118:  4b           DB  $4b
$4119:  57           DB  $57
$411a:  ea           DB  $ea
$411b:  58           DB  $58
$411c:  82           DB  $82
$411d:  5a           DB  $5a
$411e:  13           DB  $13
$411f:  5c           DB  $5c
$4120:  9c           DB  $9c
$4121:  5d           DB  $5d
$4122:  1f           DB  $1f
$4123:  5f           DB  $5f
$4124:  9a           DB  $9a
$4125:  60           DB  $60
$4126:  0d           DB  $0d
$4127:  62           DB  $62
$4128:  79           DB  $79
$4129:  63           DB  $63
$412a:  dd           DB  $dd
$412b:  64           DB  $64
$412c:  39           DB  $39
$412d:  66           DB  $66
$412e:  8d           DB  $8d
$412f:  67           DB  $67
$4130:  d9           DB  $d9
$4131:  68           DB  $68
$4132:  1d           DB  $1d
$4133:  6a           DB  $6a
$4134:  59           DB  $59
$4135:  6b           DB  $6b
$4136:  8c           DB  $8c
$4137:  6c           DB  $6c
$4138:  b7           DB  $b7
$4139:  6d           DB  $6d
$413a:  d9           DB  $d9
$413b:  6e           DB  $6e
$413c:  f3           DB  $f3
$413d:  6f           DB  $6f
$413e:  04           DB  $04
$413f:  71           DB  $71
$4140:  0c           DB  $0c
$4141:  72           DB  $72
$4142:  0b           DB  $0b
$4143:  73           DB  $73
$4144:  01           DB  $01
$4145:  74           DB  $74
$4146:  ee           DB  $ee
$4147:  74           DB  $74
$4148:  d2           DB  $d2
$4149:  75           DB  $75
$414a:  ad           DB  $ad
$414b:  76           DB  $76
$414c:  7f           DB  $7f
$414d:  77           DB  $77
$414e:  47           DB  $47
$414f:  78           DB  $78
$4150:  06           DB  $06
$4151:  79           DB  $79
$4152:  bb           DB  $bb
$4153:  79           DB  $79
$4154:  67           DB  $67
$4155:  7a           DB  $7a
$4156:  0a           DB  $0a
$4157:  7b           DB  $7b
$4158:  a2           DB  $a2
$4159:  7b           DB  $7b
$415a:  32           DB  $32
$415b:  7c           DB  $7c
$415c:  b7           DB  $b7
$415d:  7c           DB  $7c
$415e:  33           DB  $33
$415f:  7d           DB  $7d
$4160:  a5           DB  $a5
$4161:  7d           DB  $7d
$4162:  0d           DB  $0d
$4163:  7e           DB  $7e
$4164:  6c           DB  $6c
$4165:  7e           DB  $7e
$4166:  c0           DB  $c0
$4167:  7e           DB  $7e
$4168:  0b           DB  $0b
$4169:  7f           DB  $7f
$416a:  4b           DB  $4b
$416b:  7f           DB  $7f
$416c:  82           DB  $82
$416d:  7f           DB  $7f
$416e:  af           DB  $af
$416f:  7f           DB  $7f
$4170:  d2           DB  $d2
$4171:  7f           DB  $7f
$4172:  eb           DB  $eb
$4173:  7f           DB  $7f
$4174:  fa           DB  $fa
$4175:  7f           DB  $7f
$4176:  ff           DB  $ff
$4177:  7f           DB  $7f
$4178:  3d           DB  $3d
$4179:  02           DB  $02
$417a:  b7           DB  $b7
$417b:  06           DB  $06
$417c:  32           DB  $32
$417d:  0b           DB  $0b
$417e:  ae           DB  $ae
$417f:  0f           DB  $0f
$4180:  2e           DB  $2e
$4181:  14           DB  $14
$4182:  b0           DB  $b0
$4183:  18           DB  $18
$4184:  36           DB  $36
$4185:  1d           DB  $1d
$4186:  c1           DB  $c1
$4187:  21           DB  $21
$4188:  51           DB  $51
$4189:  26           DB  $26
$418a:  e8           DB  $e8
$418b:  2a           DB  $2a
$418c:  85           DB  $85
$418d:  2f           DB  $2f
$418e:  2a           DB  $2a
$418f:  34           DB  $34
$4190:  d7           DB  $d7
$4191:  38           DB  $38
$4192:  8e           DB  $8e
$4193:  3d           DB  $3d
$4194:  4e           DB  $4e
$4195:  42           DB  $42
$4196:  1a           DB  $1a
$4197:  47           DB  $47
$4198:  f2           DB  $f2
$4199:  4b           DB  $4b
$419a:  d7           DB  $d7
$419b:  50           DB  $50
$419c:  c9           DB  $c9
$419d:  55           DB  $55
$419e:  cb           DB  $cb
$419f:  5a           DB  $5a

F_P_41a0:
$41a0:  dc 5f fe            CC       $fe5f
$41a3:  64                  NOP
$41a4:  33                  INX      SP
$41a5:  6a                  MOV      L,D
$41a6:  7b                  MOV      A,E
$41a7:  6f                  MOV      L,A
$41a8:  d8                  RC
$41a9:  74                  MOV      M,H
$41aa:  4a                  MOV      C,D
$41ab:  7a                  MOV      A,D
$41ac:  d4 7f 77            CNC      $777f
$41af:  85                  ADD      L
$41b0:  35                  DCR      M
$41b1:  8b                  ADC      E
$41b2:  0e 91               MVI      C,$91
$41b4:  06 97               MVI      B,$97
$41b6:  1d                  DCR      E
$41b7:  9d                  SBB      L
$41b8:  56                  MOV      D,M
$41b9:  a3                  ANA      E
$41ba:  b3                  ORA      E
$41bb:  a9                  XRA      C
$41bc:  36 b0               MVI      M,$b0
$41be:  e1                  POP      H
$41bf:  b6                  ORA      M
$41c0:  b7                  ORA      A
$41c1:  bd                  CMP      L
$41c2:  bc                  CMP      H
$41c3:  c4 f0 cb            CNZ      $cbf0
$41c6:  59                  MOV      E,C
$41c7:  d3 fa               OUT      $fa
$41c9:  da d5 e2            JC       $e2d5
$41cc:  ef                  RST      5
$41cd:  ea 4d f3            JPE      $f34d
$41d0:  f3                  DI
$41d1:  fb                  EI

F_P_41d2:
$41d2:  3a 39 63            LDA      $6339
$41d5:  21 6c 48            LXI      H,$486c
$41d8:  cd 84 40            CALL     $4084
$41db:  42                  MOV      B,D
$41dc:  4b                  MOV      C,E
$41dd:  2a 8a 62            LHLD     $628a
$41e0:  eb                  XCHG
$41e1:  2a 88 62            LHLD     $6288
$41e4:  e5                  PUSH     H
$41e5:  d5                  PUSH     D
$41e6:  c5                  PUSH     B
$41e7:  cd 21 42            CALL     $4221
$41ea:  22 dc 62            SHLD     $62dc
$41ed:  2a 8e 62            LHLD     $628e
$41f0:  eb                  XCHG
$41f1:  2a 8c 62            LHLD     $628c
$41f4:  c1                  POP      B
$41f5:  e5                  PUSH     H
$41f6:  d5                  PUSH     D
$41f7:  cd 21 42            CALL     $4221
$41fa:  cd db 28            CALL     $28db
$41fd:  22 de 62            SHLD     $62de
$4200:  3a 39 63            LDA      $6339
$4203:  21 76 48            LXI      H,$4876
$4206:  cd 84 40            CALL     $4084
$4209:  42                  MOV      B,D
$420a:  4b                  MOV      C,E
$420b:  d1                  POP      D
$420c:  e1                  POP      H
$420d:  c5                  PUSH     B
$420e:  cd 21 42            CALL     $4221
$4211:  cd db 28            CALL     $28db
$4214:  22 e2 62            SHLD     $62e2
$4217:  c1                  POP      B
$4218:  d1                  POP      D
$4219:  e1                  POP      H
$421a:  cd 21 42            CALL     $4221
$421d:  22 e0 62            SHLD     $62e0
$4220:  c9                  RET

F_P_4221:
$4221:  cd 38 28            CALL     $2838
$4224:  eb                  XCHG
$4225:  c3 d5 28            JMP      $28d5
$4228:  cd           DB  $cd
$4229:  8f           DB  $8f
$422a:  02           DB  $02
$422b:  cd           DB  $cd
$422c:  a1           DB  $a1
$422d:  02           DB  $02
$422e:  af           DB  $af
$422f:  32           DB  $32
$4230:  68           DB  $68
$4231:  62           DB  $62
$4232:  cd           DB  $cd
$4233:  0c           DB  $0c
$4234:  11           DB  $11
$4235:  2a           DB  $2a
$4236:  50           DB  $50
$4237:  63           DB  $63
$4238:  eb           DB  $eb
$4239:  2a           DB  $2a
$423a:  4e           DB  $4e
$423b:  63           DB  $63
$423c:  e5           DB  $e5
$423d:  d5           DB  $d5
$423e:  e5           DB  $e5
$423f:  d5           DB  $d5
$4240:  e5           DB  $e5
$4241:  2a           DB  $2a
$4242:  dc           DB  $dc
$4243:  62           DB  $62
$4244:  cd           DB  $cd
$4245:  bb           DB  $bb
$4246:  28           DB  $28
$4247:  22           DB  $22
$4248:  5f           DB  $5f
$4249:  63           DB  $63
$424a:  e1           DB  $e1
$424b:  22           DB  $22
$424c:  5d           DB  $5d
$424d:  63           DB  $63
$424e:  cd           DB  $cd
$424f:  e0           DB  $e0
$4250:  1c           DB  $1c
$4251:  2a           DB  $2a
$4252:  de           DB  $de
$4253:  62           DB  $62
$4254:  d1           DB  $d1
$4255:  cd           DB  $cd
$4256:  bb           DB  $bb
$4257:  28           DB  $28
$4258:  22           DB  $22
$4259:  5f           DB  $5f
$425a:  63           DB  $63
$425b:  e1           DB  $e1
$425c:  22           DB  $22
$425d:  5d           DB  $5d
$425e:  63           DB  $63
$425f:  cd           DB  $cd
$4260:  16           DB  $16
$4261:  11           DB  $11
$4262:  cd           DB  $cd
$4263:  e0           DB  $e0
$4264:  1c           DB  $1c
$4265:  e1           DB  $e1
$4266:  22           DB  $22
$4267:  5f           DB  $5f
$4268:  63           DB  $63
$4269:  e1           DB  $e1
$426a:  22           DB  $22
$426b:  5d           DB  $5d
$426c:  63           DB  $63
$426d:  cd           DB  $cd
$426e:  0c           DB  $0c
$426f:  11           DB  $11
$4270:  cd           DB  $cd
$4271:  e0           DB  $e0
$4272:  1c           DB  $1c
$4273:  cd           DB  $cd
$4274:  9a           DB  $9a
$4275:  02           DB  $02
$4276:  c3           DB  $c3
$4277:  a8           DB  $a8
$4278:  02           DB  $02
$4279:  cd           DB  $cd
$427a:  8f           DB  $8f
$427b:  02           DB  $02
$427c:  cd           DB  $cd
$427d:  a1           DB  $a1
$427e:  02           DB  $02
$427f:  af           DB  $af
$4280:  32           DB  $32
$4281:  68           DB  $68
$4282:  62           DB  $62
$4283:  cd           DB  $cd
$4284:  0c           DB  $0c
$4285:  11           DB  $11
$4286:  2a           DB  $2a
$4287:  4e           DB  $4e
$4288:  63           DB  $63
$4289:  eb           DB  $eb
$428a:  2a           DB  $2a
$428b:  50           DB  $50
$428c:  63           DB  $63
$428d:  e5           DB  $e5
$428e:  d5           DB  $d5
$428f:  e5           DB  $e5
$4290:  d5           DB  $d5
$4291:  e5           DB  $e5
$4292:  2a           DB  $2a
$4293:  e0           DB  $e0
$4294:  62           DB  $62
$4295:  cd           DB  $cd
$4296:  bb           DB  $bb
$4297:  28           DB  $28
$4298:  22           DB  $22
$4299:  5d           DB  $5d
$429a:  63           DB  $63
$429b:  e1           DB  $e1
$429c:  22           DB  $22
$429d:  5f           DB  $5f
$429e:  63           DB  $63
$429f:  cd           DB  $cd
$42a0:  e0           DB  $e0
$42a1:  1c           DB  $1c
$42a2:  2a           DB  $2a
$42a3:  e2           DB  $e2
$42a4:  62           DB  $62
$42a5:  d1           DB  $d1
$42a6:  cd           DB  $cd
$42a7:  bb           DB  $bb
$42a8:  28           DB  $28
$42a9:  22           DB  $22
$42aa:  5d           DB  $5d
$42ab:  63           DB  $63
$42ac:  e1           DB  $e1
$42ad:  22           DB  $22
$42ae:  5f           DB  $5f
$42af:  63           DB  $63
$42b0:  cd           DB  $cd
$42b1:  16           DB  $16
$42b2:  11           DB  $11
$42b3:  cd           DB  $cd
$42b4:  e0           DB  $e0
$42b5:  1c           DB  $1c
$42b6:  e1           DB  $e1
$42b7:  22           DB  $22
$42b8:  5d           DB  $5d
$42b9:  63           DB  $63
$42ba:  e1           DB  $e1
$42bb:  22           DB  $22
$42bc:  5f           DB  $5f
$42bd:  63           DB  $63
$42be:  cd           DB  $cd
$42bf:  0c           DB  $0c
$42c0:  11           DB  $11
$42c1:  cd           DB  $cd
$42c2:  e0           DB  $e0
$42c3:  1c           DB  $1c
$42c4:  cd           DB  $cd
$42c5:  9a           DB  $9a
$42c6:  02           DB  $02
$42c7:  c3           DB  $c3
$42c8:  a8           DB  $a8
$42c9:  02           DB  $02
$42ca:  06           DB  $06
$42cb:  00           DB  $00
$42cc:  0e           DB  $0e
$42cd:  10           DB  $10
$42ce:  2a           DB  $2a
$42cf:  8a           DB  $8a
$42d0:  62           DB  $62
$42d1:  eb           DB  $eb
$42d2:  2a           DB  $2a
$42d3:  88           DB  $88
$42d4:  62           DB  $62
$42d5:  cd           DB  $cd
$42d6:  bf           DB  $bf
$42d7:  3f           DB  $3f
$42d8:  22           DB  $22
$42d9:  c4           DB  $c4
$42da:  62           DB  $62
$42db:  eb           DB  $eb
$42dc:  22           DB  $22
$42dd:  c6           DB  $c6
$42de:  62           DB  $62
$42df:  3a           DB  $3a
$42e0:  39           DB  $39
$42e1:  63           DB  $63
$42e2:  fe           DB  $fe
$42e3:  05           DB  $05
$42e4:  da           DB  $da
$42e5:  e9           DB  $e9
$42e6:  42           DB  $42
$42e7:  3e           DB  $3e
$42e8:  01           DB  $01
$42e9:  87           DB  $87
$42ea:  87           DB  $87
$42eb:  21           DB  $21
$42ec:  80           DB  $80
$42ed:  48           DB  $48
$42ee:  5f           DB  $5f
$42ef:  16           DB  $16
$42f0:  00           DB  $00
$42f1:  19           DB  $19
$42f2:  e5           DB  $e5
$42f3:  11           DB  $11
$42f4:  c4           DB  $c4
$42f5:  62           DB  $62
$42f6:  01           DB  $01
$42f7:  c4           DB  $c4
$42f8:  62           DB  $62
$42f9:  cd           DB  $cd
$42fa:  f7           DB  $f7
$42fb:  3f           DB  $3f
$42fc:  06           DB  $06
$42fd:  00           DB  $00
$42fe:  0e           DB  $0e
$42ff:  15           DB  $15
$4300:  2a           DB  $2a
$4301:  8e           DB  $8e
$4302:  62           DB  $62
$4303:  eb           DB  $eb
$4304:  2a           DB  $2a
$4305:  8c           DB  $8c
$4306:  62           DB  $62
$4307:  cd           DB  $cd
$4308:  bf           DB  $bf
$4309:  3f           DB  $3f
$430a:  22           DB  $22
$430b:  c8           DB  $c8
$430c:  62           DB  $62
$430d:  eb           DB  $eb
$430e:  22           DB  $22
$430f:  ca           DB  $ca
$4310:  62           DB  $62
$4311:  e1           DB  $e1
$4312:  11           DB  $11
$4313:  c8           DB  $c8
$4314:  62           DB  $62
$4315:  01           DB  $01
$4316:  c8           DB  $c8
$4317:  62           DB  $62
$4318:  cd           DB  $cd
$4319:  f7           DB  $f7
$431a:  3f           DB  $3f
$431b:  21           DB  $21
$431c:  ec           DB  $ec
$431d:  62           DB  $62
$431e:  3e           DB  $3e
$431f:  82           DB  $82
$4320:  b6           DB  $b6
$4321:  77           DB  $77
$4322:  c9           DB  $c9

F_P_4323:
$4323:  2a 8a 62            LHLD     $628a
$4326:  eb                  XCHG
$4327:  2a 88 62            LHLD     $6288
$432a:  01 10 00            LXI      B,$0010
$432d:  cd bf 3f            CALL     $3fbf
$4330:  01 90 01            LXI      B,$0190
$4333:  cd 38 28            CALL     $2838
$4336:  22 c4 62            SHLD     $62c4
$4339:  eb                  XCHG
$433a:  22 c6 62            SHLD     $62c6
$433d:  2a 8e 62            LHLD     $628e
$4340:  eb                  XCHG
$4341:  2a 8c 62            LHLD     $628c
$4344:  01 15 00            LXI      B,$0015
$4347:  cd bf 3f            CALL     $3fbf
$434a:  01 90 01            LXI      B,$0190
$434d:  cd 38 28            CALL     $2838
$4350:  22 c8 62            SHLD     $62c8
$4353:  eb                  XCHG
$4354:  22 ca 62            SHLD     $62ca
$4357:  21 ec 62            LXI      H,$62ec
$435a:  3e 02               MVI      A,$02
$435c:  b6                  ORA      M
$435d:  77                  MOV      M,A
$435e:  c9                  RET

F_P_435f:
$435f:  21 88 62            LXI      H,$6288
$4362:  11 88 62            LXI      D,$6288
$4365:  cd 31 2c            CALL     $2c31
$4368:  21 8c 62            LXI      H,$628c
$436b:  11 8c 62            LXI      D,$628c
$436e:  cd 31 2c            CALL     $2c31
$4371:  cd 5f 44            CALL     $445f
$4374:  c3 be 43            JMP      $43be

F_P_4377:
$4377:  7a                  MOV      A,D
$4378:  e6 80               ANI      $80
$437a:  f5                  PUSH     PSW
$437b:  7c                  MOV      A,H
$437c:  e6 80               ANI      $80
$437e:  f5                  PUSH     PSW
$437f:  3e 7f               MVI      A,$7f
$4381:  a4                  ANA      H
$4382:  67                  MOV      H,A
$4383:  b5                  ORA      L
$4384:  ca ed 43            JZ       $43ed
$4387:  3e 7f               MVI      A,$7f
$4389:  a2                  ANA      D
$438a:  57                  MOV      D,A
$438b:  b3                  ORA      E
$438c:  ca 02 44            JZ       $4402
$438f:  7c                  MOV      A,H
$4390:  ba                  CMP      D
$4391:  ca 9a 43            JZ       $439a
$4394:  d2 d9 43            JNC      $43d9
$4397:  c3 a2 43            JMP      $43a2

F_P_439a:
$439a:  7d                  MOV      A,L
$439b:  bb                  CMP      E
$439c:  ca e8 43            JZ       $43e8
$439f:  d2 d9 43            JNC      $43d9

F_P_43a2:
$43a2:  cd 27 29            CALL     $2927
$43a5:  eb                  XCHG
$43a6:  cd 11 40            CALL     $4011

F_P_43a9:
$43a9:  cd 2c 40            CALL     $402c
$43ac:  af                  XRA      A
$43ad:  32 a5 61            STA      $61a5
$43b0:  32 a9 61            STA      $61a9

F_P_43b3:
$43b3:  f1                  POP      PSW
$43b4:  21 a6 61            LXI      H,$61a6
$43b7:  77                  MOV      M,A
$43b8:  f1                  POP      PSW
$43b9:  21 aa 61            LXI      H,$61aa
$43bc:  77                  MOV      M,A
$43bd:  c9                  RET

F_P_43be:
$43be:  21 a3 61            LXI      H,$61a3
$43c1:  11 d4 62            LXI      D,$62d4
$43c4:  cd 31 2c            CALL     $2c31
$43c7:  21 a7 61            LXI      H,$61a7
$43ca:  11 d8 62            LXI      D,$62d8
$43cd:  cd 31 2c            CALL     $2c31
$43d0:  c9                  RET

F_P_43d1:
$43d1:  21 ec 62            LXI      H,$62ec
$43d4:  3e 02               MVI      A,$02
$43d6:  b6                  ORA      M
$43d7:  77                  MOV      M,A
$43d8:  c9                  RET

F_P_43d9:
$43d9:  eb                  XCHG
$43da:  cd 27 29            CALL     $2927
$43dd:  eb                  XCHG
$43de:  cd 11 40            CALL     $4011
$43e1:  3e 5a               MVI      A,$5a
$43e3:  90                  SUB      B
$43e4:  47                  MOV      B,A
$43e5:  c3 a9 43            JMP      $43a9

F_P_43e8:
$43e8:  06 2d               MVI      B,$2d
$43ea:  c3 a9 43            JMP      $43a9

F_P_43ed:
$43ed:  21 01 00            LXI      H,$0001
$43f0:  22 a9 61            SHLD     $61a9
$43f3:  21 00 00            LXI      H,$0000
$43f6:  22 a5 61            SHLD     $61a5
$43f9:  22 a7 61            SHLD     $61a7
$43fc:  22 a3 61            SHLD     $61a3
$43ff:  c3 b3 43            JMP      $43b3

F_P_4402:
$4402:  21 01 00            LXI      H,$0001
$4405:  22 a5 61            SHLD     $61a5
$4408:  21 00 00            LXI      H,$0000
$440b:  22 a3 61            SHLD     $61a3
$440e:  22 a9 61            SHLD     $61a9
$4411:  22 a7 61            SHLD     $61a7
$4414:  c3 b3 43            JMP      $43b3

F_P_4417:
$4417:  3a 39 63            LDA      $6339
$441a:  21 76 48            LXI      H,$4876
$441d:  cd 84 40            CALL     $4084
$4420:  d5                  PUSH     D
$4421:  2a 8a 62            LHLD     $628a
$4424:  eb                  XCHG
$4425:  2a 88 62            LHLD     $6288
$4428:  c1                  POP      B
$4429:  cd 38 28            CALL     $2838
$442c:  22 88 62            SHLD     $6288
$442f:  eb                  XCHG
$4430:  22 8a 62            SHLD     $628a
$4433:  3a 39 63            LDA      $6339
$4436:  21 6c 48            LXI      H,$486c
$4439:  cd 84 40            CALL     $4084
$443c:  d5                  PUSH     D
$443d:  2a 8e 62            LHLD     $628e
$4440:  eb                  XCHG
$4441:  2a 8c 62            LHLD     $628c
$4444:  c1                  POP      B
$4445:  cd 38 28            CALL     $2838
$4448:  22 8c 62            SHLD     $628c
$444b:  eb                  XCHG
$444c:  22 8e 62            SHLD     $628e
$444f:  cd 5f 44            CALL     $445f
$4452:  c3 be 43            JMP      $43be

F_P_4455:
$4455:  06 04               MVI      B,$04

F_P_4457:
$4457:  be                  CMP      M
$4458:  c0                  RNZ
$4459:  23                  INX      H
$445a:  05                  DCR      B
$445b:  c2 57 44            JNZ      $4457
$445e:  c9                  RET

F_P_445f:
$445f:  cd be 43            CALL     $43be
$4462:  cd d1 43            CALL     $43d1
$4465:  2a 8a 62            LHLD     $628a
$4468:  7c                  MOV      A,H
$4469:  e6 80               ANI      $80
$446b:  f5                  PUSH     PSW
$446c:  7c                  MOV      A,H
$446d:  e6 7f               ANI      $7f
$446f:  67                  MOV      H,A
$4470:  22 8a 62            SHLD     $628a
$4473:  2a 8e 62            LHLD     $628e
$4476:  7c                  MOV      A,H
$4477:  e6 80               ANI      $80
$4479:  f5                  PUSH     PSW
$447a:  7c                  MOV      A,H
$447b:  e6 7f               ANI      $7f
$447d:  67                  MOV      H,A
$447e:  22 8e 62            SHLD     $628e
$4481:  af                  XRA      A
$4482:  21 88 62            LXI      H,$6288
$4485:  cd 55 44            CALL     $4455
$4488:  ca 02 44            JZ       $4402
$448b:  21 8c 62            LXI      H,$628c
$448e:  cd 55 44            CALL     $4455
$4491:  ca ed 43            JZ       $43ed
$4494:  21 88 62            LXI      H,$6288
$4497:  11 8c 62            LXI      D,$628c
$449a:  cd e6 2b            CALL     $2be6
$449d:  ca e8 43            JZ       $43e8
$44a0:  f5                  PUSH     PSW
$44a1:  21 88 62            LXI      H,$6288
$44a4:  11 8c 62            LXI      D,$628c
$44a7:  da ab 44            JC       $44ab
$44aa:  eb                  XCHG

F_P_44ab:
$44ab:  cd f1 29            CALL     $29f1
$44ae:  cd 11 40            CALL     $4011
$44b1:  f1                  POP      PSW
$44b2:  da a9 43            JC       $43a9
$44b5:  3e 5a               MVI      A,$5a
$44b7:  90                  SUB      B
$44b8:  47                  MOV      B,A
$44b9:  c3 a9 43            JMP      $43a9

F_P_44bc:
$44bc:  3a 90 62            LDA      $6290
$44bf:  fe 06               CPI      $06
$44c1:  da c6 44            JC       $44c6
$44c4:  3e 00               MVI      A,$00

F_P_44c6:
$44c6:  cd 83 3e            CALL     $3e83
$44c9:  22 9a 62            SHLD     $629a
$44cc:  c9                  RET

F_P_44cd:
$44cd:  3a 91 62            LDA      $6291
$44d0:  fe 06               CPI      $06
$44d2:  da d7 44            JC       $44d7
$44d5:  3e 01               MVI      A,$01

F_P_44d7:
$44d7:  cd 83 3e            CALL     $3e83
$44da:  22 98 62            SHLD     $6298
$44dd:  c9                  RET

F_P_44de:
$44de:  2a 98 62            LHLD     $6298
$44e1:  22 96 62            SHLD     $6296
$44e4:  c9                  RET

F_P_44e5:
$44e5:  2a 9a 62            LHLD     $629a
$44e8:  22 96 62            SHLD     $6296
$44eb:  c9                  RET
$44ec:  08                  NOP
$44ed:  61                  MOV      H,C
$44ee:  00                  NOP
$44ef:  00                  NOP
$44f0:  00                  NOP
$44f1:  80                  ADD      B
$44f2:  00                  NOP
$44f3:  00                  NOP
$44f4:  8c                  ADC      H
$44f5:  00                  NOP
$44f6:  99                  SBB      C
$44f7:  00                  NOP
$44f8:  00                  NOP
$44f9:  88                  ADC      B
$44fa:  8c                  ADC      H
$44fb:  88                  ADC      B
$44fc:  99                  SBB      C
$44fd:  88                  ADC      B
$44fe:  00                  NOP
$44ff:  90                  SUB      B
$4500:  8c                  ADC      H
$4501:  90                  SUB      B
$4502:  99                  SBB      C
$4503:  90                  SUB      B
$4504:  00                  NOP
$4505:  00                  NOP
$4506:  0c                  INR      C
$4507:  08                  NOP
$4508:  8c                  ADC      H
$4509:  08                  NOP
$450a:  a5                  ANA      L
$450b:  08                  NOP
$450c:  0c                  INR      C
$450d:  88                  ADC      B
$450e:  8c                  ADC      H
$450f:  88                  ADC      B
$4510:  a5                  ANA      L
$4511:  88                  ADC      B
$4512:  0c                  INR      C

F_P_4513:
$4513:  98                  SBB      B
$4514:  8c                  ADC      H
$4515:  98                  SBB      B
$4516:  a5                  ANA      L
$4517:  98                  SBB      B
$4518:  4c                  MOV      C,H
$4519:  46                  MOV      B,M
$451a:  ac                  XRA      H
$451b:  46                  MOV      B,M
$451c:  0c                  INR      C
$451d:  47                  MOV      B,A
$451e:  ec 47 4c            CPE      $4c47
$4521:  46                  MOV      B,M
$4522:  ac                  XRA      H
$4523:  46                  MOV      B,M
$4524:  11 49 14            LXI      D,$1449
$4527:  49                  NOP
$4528:  27                  DAA
$4529:  49                  NOP
$452a:  3c                  INR      A
$452b:  49                  NOP
$452c:  55                  MOV      D,L
$452d:  49                  NOP
$452e:  8a                  ADC      D
$452f:  49                  NOP
$4530:  c9                  RET
$4531:  49                  NOP
$4532:  f2 49 fd            JP       $fd49
$4535:  49                  NOP
$4536:  0c                  INR      C
$4537:  4a                  MOV      C,D
$4538:  1b                  DCX      D
$4539:  4a                  MOV      C,D
$453a:  2e 4a               MVI      L,$4a
$453c:  3b                  DCX      SP
$453d:  4a                  MOV      C,D
$453e:  4e                  MOV      C,M
$453f:  4a                  MOV      C,D
$4540:  55                  MOV      D,L
$4541:  4a                  MOV      C,D
$4542:  62                  MOV      H,D
$4543:  4a                  MOV      C,D
$4544:  69                  MOV      L,C
$4545:  4a                  MOV      C,D
$4546:  86                  ADD      M
$4547:  4a                  MOV      C,D
$4548:  8f                  ADC      A
$4549:  4a                  MOV      C,D
$454a:  a4                  ANA      H
$454b:  4a                  MOV      C,D
$454c:  bb                  CMP      E
$454d:  4a                  MOV      C,D
$454e:  ca 4a e1            JZ       $e14a
$4551:  4a                  MOV      C,D
$4552:  04                  INR      B
$4553:  4b                  MOV      C,E
$4554:  0f                  RRC
$4555:  4b                  MOV      C,E
$4556:  42                  MOV      B,D
$4557:  4b                  MOV      C,E
$4558:  65                  MOV      H,L
$4559:  4b                  MOV      C,E
$455a:  7e                  MOV      A,M
$455b:  4b                  MOV      C,E
$455c:  9d                  SBB      L
$455d:  4b                  MOV      C,E
$455e:  a6                  ANA      M
$455f:  4b                  MOV      C,E
$4560:  b3                  ORA      E
$4561:  4b                  MOV      C,E
$4562:  bc                  CMP      H
$4563:  4b                  MOV      C,E
$4564:  a8                  XRA      B
$4565:  51                  MOV      D,C
$4566:  22 4f e1            SHLD     $e14f
$4569:  51                  MOV      D,C
$456a:  06 52               MVI      B,$52
$456c:  19                  DAD      D
$456d:  52                  NOP
$456e:  2e 52               MVI      L,$52
$4570:  3f                  CMC
$4571:  52                  NOP
$4572:  4e                  MOV      C,M
$4573:  52                  NOP
$4574:  65                  MOV      H,L
$4575:  52                  NOP
$4576:  78                  MOV      A,B
$4577:  52                  NOP
$4578:  7f                  NOP
$4579:  52                  NOP
$457a:  8c                  ADC      H
$457b:  52                  NOP
$457c:  9f                  SBB      A
$457d:  52                  NOP
$457e:  a8                  XRA      B
$457f:  52                  NOP
$4580:  b5                  ORA      L
$4581:  52                  NOP
$4582:  c0                  RNZ
$4583:  52                  NOP
$4584:  dd                  NOP
$4585:  52                  NOP
$4586:  f2 52 15            JP       $1552
$4589:  53                  MOV      D,E
$458a:  30                  NOP
$458b:  53                  MOV      D,E
$458c:  4b                  MOV      C,E
$458d:  53                  MOV      D,E
$458e:  58                  MOV      E,B
$458f:  53                  MOV      D,E
$4590:  6b                  MOV      L,E
$4591:  53                  MOV      D,E
$4592:  74                  MOV      M,H
$4593:  53                  MOV      D,E
$4594:  81                  ADD      C
$4595:  53                  MOV      D,E
$4596:  8e                  ADC      M
$4597:  53                  MOV      D,E
$4598:  9d                  SBB      L
$4599:  53                  MOV      D,E
$459a:  a8                  XRA      B
$459b:  53                  MOV      D,E
$459c:  b3                  ORA      E
$459d:  53                  MOV      D,E
$459e:  ba                  CMP      D
$459f:  53                  MOV      D,E
$45a0:  c5                  PUSH     B
$45a1:  53                  MOV      D,E
$45a2:  ce 53               ACI      $53
$45a4:  d5                  PUSH     D
$45a5:  53                  MOV      D,E
$45a6:  0a                  LDAX     B
$45a7:  4c                  MOV      C,H
$45a8:  e0                  RPO
$45a9:  53                  MOV      D,E
$45aa:  f5                  PUSH     PSW
$45ab:  53                  MOV      D,E
$45ac:  08                  NOP
$45ad:  54                  MOV      D,H
$45ae:  1d                  DCR      E
$45af:  54                  MOV      D,H
$45b0:  38                  NOP
$45b1:  54                  MOV      D,H
$45b2:  4b                  MOV      C,E
$45b3:  54                  MOV      D,H
$45b4:  68                  MOV      L,B
$45b5:  54                  MOV      D,H
$45b6:  7b                  MOV      A,E
$45b7:  54                  MOV      D,H
$45b8:  86                  ADD      M
$45b9:  54                  MOV      D,H
$45ba:  9f                  SBB      A
$45bb:  54                  MOV      D,H
$45bc:  b2                  ORA      D
$45bd:  54                  MOV      D,H
$45be:  bf                  CMP      A
$45bf:  54                  MOV      D,H
$45c0:  d4 54 f8            CNC      $f854
$45c3:  54                  MOV      D,H
$45c4:  e3                  XTHL
$45c5:  54                  MOV      D,H
$45c6:  15                  DCR      D
$45c7:  55                  MOV      D,L
$45c8:  2a 55 37            LHLD     $3755
$45cb:  55                  MOV      D,L
$45cc:  54                  MOV      D,H
$45cd:  55                  MOV      D,L
$45ce:  61                  MOV      H,C
$45cf:  55                  MOV      D,L
$45d0:  70                  MOV      M,B
$45d1:  55                  MOV      D,L
$45d2:  79                  MOV      A,C
$45d3:  55                  MOV      D,L
$45d4:  86                  ADD      M
$45d5:  55                  MOV      D,L
$45d6:  93                  SUB      E
$45d7:  55                  MOV      D,L
$45d8:  a4                  ANA      H
$45d9:  55                  MOV      D,L
$45da:  af                  XRA      A
$45db:  55                  MOV      D,L
$45dc:  c8                  RZ
$45dd:  55                  MOV      D,L
$45de:  cf                  RST      1
$45df:  55                  MOV      D,L
$45e0:  e8                  RPE
$45e1:  55                  MOV      D,L
$45e2:  94                  SUB      H
$45e3:  48                  MOV      C,B
$45e4:  e3                  XTHL
$45e5:  4b                  MOV      C,E
$45e6:  0a                  LDAX     B
$45e7:  4c                  MOV      C,H
$45e8:  25                  DCR      H
$45e9:  4c                  MOV      C,H
$45ea:  42                  MOV      B,D
$45eb:  4c                  MOV      C,H
$45ec:  57                  MOV      D,A
$45ed:  4c                  MOV      C,H
$45ee:  76                  HLT
$45ef:  4c                  MOV      C,H
$45f0:  91                  SUB      C
$45f1:  4c                  MOV      C,H
$45f2:  b4                  ORA      H
$45f3:  4c                  MOV      C,H
$45f4:  d3 4c               OUT      $4c
$45f6:  e0                  RPO
$45f7:  4c                  MOV      C,H
$45f8:  ef                  RST      5
$45f9:  4c                  MOV      C,H
$45fa:  04                  INR      B
$45fb:  4d                  MOV      C,L
$45fc:  17                  RAL
$45fd:  4d                  MOV      C,L
$45fe:  22 4d 2f            SHLD     $2f4d
$4601:  4d                  MOV      C,L
$4602:  42                  MOV      B,D
$4603:  4d                  MOV      C,L
$4604:  5f                  MOV      E,A
$4605:  4d                  MOV      C,L
$4606:  6e                  MOV      L,M
$4607:  4d                  MOV      C,L
$4608:  8d                  ADC      L
$4609:  4d                  MOV      C,L
$460a:  a6                  ANA      M
$460b:  4d                  MOV      C,L
$460c:  b9                  CMP      C
$460d:  4d                  MOV      C,L
$460e:  ce 4d               ACI      $4d
$4610:  e7                  RST      4
$4611:  4d                  MOV      C,L
$4612:  04                  INR      B
$4613:  4e                  MOV      C,M
$4614:  2d                  DCR      L
$4615:  4e                  MOV      C,M
$4616:  46                  MOV      B,M
$4617:  4e                  MOV      C,M
$4618:  61                  MOV      H,C
$4619:  4e                  MOV      C,M
$461a:  88                  ADC      B
$461b:  4e                  MOV      C,M
$461c:  9d                  SBB      L
$461d:  4e                  MOV      C,M
$461e:  b6                  ORA      M
$461f:  4e                  MOV      C,M
$4620:  d1                  POP      D
$4621:  4e                  MOV      C,M
$4622:  e4 4e fb            CPO      $fb4e
$4625:  4e                  MOV      C,M
$4626:  22 4f 35            SHLD     $354f
$4629:  4f                  MOV      C,A
$462a:  50                  MOV      D,B
$462b:  4f                  MOV      C,A
$462c:  61                  MOV      H,C
$462d:  4f                  MOV      C,A
$462e:  76                  HLT
$462f:  4f                  MOV      C,A
$4630:  87                  ADD      A
$4631:  4f                  MOV      C,A
$4632:  aa                  XRA      D
$4633:  4f                  MOV      C,A
$4634:  b3                  ORA      E
$4635:  4f                  MOV      C,A
$4636:  c0                  RNZ
$4637:  4f                  MOV      C,A
$4638:  cb 4f dc            JMP      $dc4f
$463b:  4f           DB  $4f
$463c:  ef           DB  $ef
$463d:  4f           DB  $4f
$463e:  fa           DB  $fa
$463f:  4f           DB  $4f
$4640:  07           DB  $07
$4641:  50           DB  $50
$4642:  1a           DB  $1a
$4643:  50           DB  $50
$4644:  37           DB  $37
$4645:  50           DB  $50
$4646:  42           DB  $42
$4647:  50           DB  $50
$4648:  61           DB  $61
$4649:  50           DB  $50
$464a:  76           DB  $76
$464b:  50           DB  $50
$464c:  89           DB  $89
$464d:  50           DB  $50
$464e:  96           DB  $96
$464f:  50           DB  $50
$4650:  af           DB  $af
$4651:  50           DB  $50
$4652:  cc           DB  $cc
$4653:  50           DB  $50
$4654:  f1           DB  $f1
$4655:  50           DB  $50
$4656:  0a           DB  $0a
$4657:  51           DB  $51
$4658:  29           DB  $29
$4659:  51           DB  $51
$465a:  54           DB  $54
$465b:  51           DB  $51
$465c:  65           DB  $65
$465d:  51           DB  $51
$465e:  7e           DB  $7e
$465f:  51           DB  $51
$4660:  95           DB  $95
$4661:  51           DB  $51
$4662:  94           DB  $94
$4663:  48           DB  $48
$4664:  97           DB  $97
$4665:  48           DB  $48
$4666:  c0           DB  $c0
$4667:  48           DB  $48
$4668:  db           DB  $db
$4669:  48           DB  $48
$466a:  0e           DB  $0e
$466b:  49           DB  $49
$466c:  00           DB  $00
$466d:  01           DB  $01
$466e:  02           DB  $02
$466f:  03           DB  $03
$4670:  04           DB  $04
$4671:  05           DB  $05
$4672:  06           DB  $06
$4673:  07           DB  $07
$4674:  08           DB  $08
$4675:  09           DB  $09
$4676:  0a           DB  $0a
$4677:  0b           DB  $0b
$4678:  0c           DB  $0c
$4679:  0d           DB  $0d
$467a:  0e           DB  $0e
$467b:  0f           DB  $0f
$467c:  10           DB  $10
$467d:  11           DB  $11
$467e:  12           DB  $12
$467f:  13           DB  $13
$4680:  14           DB  $14
$4681:  15           DB  $15
$4682:  16           DB  $16
$4683:  17           DB  $17
$4684:  18           DB  $18
$4685:  19           DB  $19
$4686:  1a           DB  $1a
$4687:  1b           DB  $1b
$4688:  1c           DB  $1c
$4689:  1d           DB  $1d
$468a:  1e           DB  $1e
$468b:  1f           DB  $1f
$468c:  20           DB  $20
$468d:  21           DB  $21
$468e:  22           DB  $22
$468f:  23           DB  $23
$4690:  24           DB  $24
$4691:  25           DB  $25
$4692:  26           DB  $26
$4693:  27           DB  $27
$4694:  28           DB  $28
$4695:  29           DB  $29
$4696:  2a           DB  $2a
$4697:  2b           DB  $2b
$4698:  2c           DB  $2c
$4699:  2d           DB  $2d
$469a:  2e           DB  $2e
$469b:  2f           DB  $2f
$469c:  30           DB  $30
$469d:  31           DB  $31
$469e:  32           DB  $32
$469f:  33           DB  $33
$46a0:  34           DB  $34
$46a1:  35           DB  $35
$46a2:  36           DB  $36
$46a3:  37           DB  $37
$46a4:  38           DB  $38
$46a5:  39           DB  $39
$46a6:  3a           DB  $3a
$46a7:  3b           DB  $3b
$46a8:  3c           DB  $3c
$46a9:  3d           DB  $3d
$46aa:  3e           DB  $3e
$46ab:  3f           DB  $3f
$46ac:  40           DB  $40
$46ad:  41           DB  $41
$46ae:  42           DB  $42
$46af:  43           DB  $43
$46b0:  44           DB  $44
$46b1:  45           DB  $45
$46b2:  46           DB  $46
$46b3:  47           DB  $47
$46b4:  48           DB  $48
$46b5:  49           DB  $49
$46b6:  4a           DB  $4a
$46b7:  4b           DB  $4b
$46b8:  4c           DB  $4c
$46b9:  4d           DB  $4d
$46ba:  4e           DB  $4e
$46bb:  4f           DB  $4f
$46bc:  50           DB  $50
$46bd:  51           DB  $51
$46be:  52           DB  $52
$46bf:  53           DB  $53
$46c0:  54           DB  $54
$46c1:  55           DB  $55
$46c2:  56           DB  $56
$46c3:  57           DB  $57
$46c4:  58           DB  $58
$46c5:  59           DB  $59
$46c6:  5a           DB  $5a
$46c7:  5b           DB  $5b
$46c8:  5c           DB  $5c
$46c9:  5d           DB  $5d
$46ca:  5e           DB  $5e
$46cb:  00           DB  $00
$46cc:  00           DB  $00
$46cd:  01           DB  $01
$46ce:  02           DB  $02
$46cf:  03           DB  $03
$46d0:  04           DB  $04
$46d1:  05           DB  $05
$46d2:  06           DB  $06
$46d3:  07           DB  $07
$46d4:  08           DB  $08
$46d5:  09           DB  $09
$46d6:  0a           DB  $0a
$46d7:  0b           DB  $0b
$46d8:  0c           DB  $0c
$46d9:  0d           DB  $0d
$46da:  0e           DB  $0e
$46db:  0f           DB  $0f
$46dc:  10           DB  $10
$46dd:  11           DB  $11
$46de:  12           DB  $12
$46df:  13           DB  $13
$46e0:  14           DB  $14
$46e1:  15           DB  $15
$46e2:  16           DB  $16
$46e3:  17           DB  $17
$46e4:  18           DB  $18
$46e5:  19           DB  $19
$46e6:  1a           DB  $1a
$46e7:  1b           DB  $1b
$46e8:  1c           DB  $1c
$46e9:  1d           DB  $1d
$46ea:  1e           DB  $1e
$46eb:  1f           DB  $1f
$46ec:  60           DB  $60
$46ed:  61           DB  $61
$46ee:  62           DB  $62
$46ef:  63           DB  $63
$46f0:  64           DB  $64
$46f1:  65           DB  $65
$46f2:  66           DB  $66
$46f3:  67           DB  $67
$46f4:  68           DB  $68
$46f5:  69           DB  $69
$46f6:  6a           DB  $6a
$46f7:  6b           DB  $6b
$46f8:  6c           DB  $6c
$46f9:  6d           DB  $6d
$46fa:  6e           DB  $6e
$46fb:  6f           DB  $6f
$46fc:  70           DB  $70
$46fd:  71           DB  $71
$46fe:  72           DB  $72
$46ff:  73           DB  $73
$4700:  74           DB  $74
$4701:  75           DB  $75
$4702:  76           DB  $76
$4703:  77           DB  $77
$4704:  78           DB  $78
$4705:  79           DB  $79
$4706:  7a           DB  $7a
$4707:  7b           DB  $7b
$4708:  7c           DB  $7c
$4709:  7d           DB  $7d
$470a:  7e           DB  $7e
$470b:  7f           DB  $7f
$470c:  80           DB  $80
$470d:  81           DB  $81
$470e:  82           DB  $82
$470f:  83           DB  $83
$4710:  84           DB  $84
$4711:  85           DB  $85
$4712:  86           DB  $86
$4713:  87           DB  $87
$4714:  88           DB  $88
$4715:  89           DB  $89
$4716:  8a           DB  $8a
$4717:  8b           DB  $8b
$4718:  8c           DB  $8c
$4719:  8d           DB  $8d
$471a:  8e           DB  $8e
$471b:  8f           DB  $8f
$471c:  90           DB  $90
$471d:  91           DB  $91
$471e:  92           DB  $92
$471f:  93           DB  $93
$4720:  94           DB  $94
$4721:  95           DB  $95
$4722:  96           DB  $96
$4723:  97           DB  $97
$4724:  98           DB  $98
$4725:  99           DB  $99
$4726:  9a           DB  $9a
$4727:  9b           DB  $9b
$4728:  9c           DB  $9c
$4729:  9d           DB  $9d
$472a:  9e           DB  $9e
$472b:  9f           DB  $9f
$472c:  00           DB  $00
$472d:  01           DB  $01
$472e:  02           DB  $02
$472f:  03           DB  $03
$4730:  04           DB  $04
$4731:  05           DB  $05
$4732:  06           DB  $06
$4733:  07           DB  $07
$4734:  08           DB  $08
$4735:  09           DB  $09
$4736:  0a           DB  $0a
$4737:  0b           DB  $0b
$4738:  0c           DB  $0c
$4739:  0d           DB  $0d
$473a:  0e           DB  $0e
$473b:  0f           DB  $0f
$473c:  10           DB  $10
$473d:  11           DB  $11
$473e:  12           DB  $12
$473f:  13           DB  $13
$4740:  14           DB  $14
$4741:  15           DB  $15
$4742:  16           DB  $16
$4743:  17           DB  $17
$4744:  18           DB  $18
$4745:  19           DB  $19
$4746:  1a           DB  $1a
$4747:  1b           DB  $1b
$4748:  1c           DB  $1c
$4749:  1d           DB  $1d
$474a:  1e           DB  $1e
$474b:  1f           DB  $1f
$474c:  20           DB  $20
$474d:  21           DB  $21
$474e:  22           DB  $22
$474f:  23           DB  $23
$4750:  24           DB  $24
$4751:  25           DB  $25
$4752:  26           DB  $26
$4753:  27           DB  $27
$4754:  28           DB  $28
$4755:  29           DB  $29
$4756:  2a           DB  $2a
$4757:  2b           DB  $2b
$4758:  2c           DB  $2c
$4759:  2d           DB  $2d
$475a:  2e           DB  $2e
$475b:  2f           DB  $2f
$475c:  30           DB  $30
$475d:  31           DB  $31
$475e:  32           DB  $32
$475f:  33           DB  $33
$4760:  34           DB  $34
$4761:  35           DB  $35
$4762:  36           DB  $36
$4763:  37           DB  $37
$4764:  38           DB  $38
$4765:  39           DB  $39
$4766:  3a           DB  $3a
$4767:  3b           DB  $3b
$4768:  3c           DB  $3c
$4769:  3d           DB  $3d
$476a:  3e           DB  $3e
$476b:  3f           DB  $3f
$476c:  40           DB  $40
$476d:  41           DB  $41
$476e:  42           DB  $42
$476f:  43           DB  $43
$4770:  44           DB  $44
$4771:  45           DB  $45
$4772:  46           DB  $46
$4773:  47           DB  $47
$4774:  48           DB  $48
$4775:  49           DB  $49
$4776:  4a           DB  $4a
$4777:  4b           DB  $4b
$4778:  4c           DB  $4c
$4779:  4d           DB  $4d
$477a:  4e           DB  $4e
$477b:  4f           DB  $4f
$477c:  50           DB  $50
$477d:  51           DB  $51
$477e:  52           DB  $52
$477f:  53           DB  $53
$4780:  54           DB  $54
$4781:  55           DB  $55
$4782:  56           DB  $56
$4783:  57           DB  $57
$4784:  58           DB  $58
$4785:  59           DB  $59
$4786:  5a           DB  $5a
$4787:  5b           DB  $5b
$4788:  5c           DB  $5c
$4789:  5d           DB  $5d
$478a:  5e           DB  $5e
$478b:  5f           DB  $5f
$478c:  5f           DB  $5f
$478d:  5f           DB  $5f
$478e:  5f           DB  $5f
$478f:  5f           DB  $5f
$4790:  5f           DB  $5f
$4791:  5f           DB  $5f
$4792:  5f           DB  $5f
$4793:  5f           DB  $5f
$4794:  5f           DB  $5f
$4795:  5f           DB  $5f
$4796:  5f           DB  $5f
$4797:  5f           DB  $5f
$4798:  5f           DB  $5f
$4799:  5f           DB  $5f
$479a:  5f           DB  $5f
$479b:  5f           DB  $5f
$479c:  5f           DB  $5f
$479d:  5f           DB  $5f
$479e:  5f           DB  $5f
$479f:  5f           DB  $5f
$47a0:  5f           DB  $5f
$47a1:  5f           DB  $5f
$47a2:  5f           DB  $5f
$47a3:  5f           DB  $5f
$47a4:  5f           DB  $5f
$47a5:  5f           DB  $5f
$47a6:  5f           DB  $5f
$47a7:  5f           DB  $5f
$47a8:  5f           DB  $5f
$47a9:  5f           DB  $5f
$47aa:  5f           DB  $5f
$47ab:  5f           DB  $5f
$47ac:  5f           DB  $5f
$47ad:  a0           DB  $a0
$47ae:  5f           DB  $5f
$47af:  5f           DB  $5f
$47b0:  5f           DB  $5f
$47b1:  5f           DB  $5f
$47b2:  5f           DB  $5f
$47b3:  5f           DB  $5f
$47b4:  5f           DB  $5f
$47b5:  5f           DB  $5f
$47b6:  5f           DB  $5f
$47b7:  5f           DB  $5f
$47b8:  5f           DB  $5f
$47b9:  5f           DB  $5f
$47ba:  5f           DB  $5f
$47bb:  5f           DB  $5f
$47bc:  81           DB  $81
$47bd:  82           DB  $82
$47be:  97           DB  $97
$47bf:  87           DB  $87
$47c0:  84           DB  $84
$47c1:  85           DB  $85
$47c2:  96           DB  $96
$47c3:  9a           DB  $9a
$47c4:  89           DB  $89
$47c5:  8a           DB  $8a
$47c6:  8b           DB  $8b
$47c7:  8c           DB  $8c
$47c8:  8d           DB  $8d
$47c9:  8e           DB  $8e
$47ca:  8f           DB  $8f
$47cb:  90           DB  $90
$47cc:  92           DB  $92
$47cd:  93           DB  $93
$47ce:  94           DB  $94
$47cf:  95           DB  $95
$47d0:  86           DB  $86
$47d1:  88           DB  $88
$47d2:  83           DB  $83
$47d3:  9e           DB  $9e
$47d4:  9b           DB  $9b
$47d5:  9d           DB  $9d
$47d6:  a1           DB  $a1
$47d7:  99           DB  $99
$47d8:  98           DB  $98
$47d9:  9c           DB  $9c
$47da:  80           DB  $80
$47db:  91           DB  $91
$47dc:  61           DB  $61
$47dd:  62           DB  $62
$47de:  77           DB  $77
$47df:  67           DB  $67
$47e0:  64           DB  $64
$47e1:  65           DB  $65
$47e2:  76           DB  $76
$47e3:  7a           DB  $7a
$47e4:  69           DB  $69
$47e5:  6a           DB  $6a
$47e6:  6b           DB  $6b
$47e7:  6c           DB  $6c
$47e8:  6d           DB  $6d
$47e9:  6e           DB  $6e
$47ea:  6f           DB  $6f
$47eb:  70           DB  $70
$47ec:  72           DB  $72
$47ed:  73           DB  $73
$47ee:  74           DB  $74
$47ef:  75           DB  $75
$47f0:  66           DB  $66
$47f1:  68           DB  $68
$47f2:  63           DB  $63
$47f3:  7e           DB  $7e
$47f4:  7b           DB  $7b
$47f5:  7d           DB  $7d
$47f6:  7f           DB  $7f
$47f7:  79           DB  $79
$47f8:  78           DB  $78
$47f9:  7c           DB  $7c
$47fa:  60           DB  $60
$47fb:  71           DB  $71
$47fc:  a0           DB  $a0
$47fd:  a2           DB  $a2
$47fe:  5f           DB  $5f
$47ff:  5f           DB  $5f
$4800:  5f           DB  $5f
$4801:  5f           DB  $5f
$4802:  5f           DB  $5f
$4803:  5f           DB  $5f
$4804:  5f           DB  $5f
$4805:  5f           DB  $5f
$4806:  5f           DB  $5f
$4807:  5f           DB  $5f
$4808:  5f           DB  $5f
$4809:  5f           DB  $5f
$480a:  5f           DB  $5f
$480b:  5f           DB  $5f
$480c:  00           DB  $00
$480d:  01           DB  $01
$480e:  02           DB  $02
$480f:  03           DB  $03
$4810:  04           DB  $04
$4811:  05           DB  $05
$4812:  06           DB  $06
$4813:  07           DB  $07
$4814:  08           DB  $08
$4815:  09           DB  $09
$4816:  0a           DB  $0a
$4817:  0b           DB  $0b
$4818:  0c           DB  $0c
$4819:  0d           DB  $0d
$481a:  0e           DB  $0e
$481b:  0f           DB  $0f
$481c:  10           DB  $10
$481d:  11           DB  $11
$481e:  12           DB  $12
$481f:  13           DB  $13
$4820:  14           DB  $14
$4821:  15           DB  $15
$4822:  16           DB  $16
$4823:  17           DB  $17
$4824:  18           DB  $18
$4825:  19           DB  $19
$4826:  1a           DB  $1a
$4827:  1b           DB  $1b
$4828:  1c           DB  $1c
$4829:  1d           DB  $1d
$482a:  1e           DB  $1e
$482b:  1f           DB  $1f
$482c:  20           DB  $20
$482d:  21           DB  $21
$482e:  22           DB  $22
$482f:  23           DB  $23
$4830:  24           DB  $24
$4831:  25           DB  $25
$4832:  26           DB  $26
$4833:  27           DB  $27
$4834:  28           DB  $28
$4835:  29           DB  $29
$4836:  2a           DB  $2a
$4837:  2b           DB  $2b
$4838:  2c           DB  $2c
$4839:  2d           DB  $2d
$483a:  2e           DB  $2e
$483b:  2f           DB  $2f
$483c:  30           DB  $30
$483d:  31           DB  $31
$483e:  32           DB  $32
$483f:  33           DB  $33
$4840:  34           DB  $34
$4841:  35           DB  $35
$4842:  36           DB  $36
$4843:  37           DB  $37
$4844:  38           DB  $38
$4845:  39           DB  $39
$4846:  3a           DB  $3a
$4847:  3b           DB  $3b
$4848:  3c           DB  $3c
$4849:  3d           DB  $3d
$484a:  3e           DB  $3e
$484b:  3f           DB  $3f
$484c:  80           DB  $80
$484d:  81           DB  $81
$484e:  82           DB  $82
$484f:  83           DB  $83
$4850:  84           DB  $84
$4851:  85           DB  $85
$4852:  86           DB  $86
$4853:  87           DB  $87
$4854:  88           DB  $88
$4855:  89           DB  $89
$4856:  8a           DB  $8a
$4857:  8b           DB  $8b
$4858:  8c           DB  $8c
$4859:  8d           DB  $8d
$485a:  8e           DB  $8e
$485b:  8f           DB  $8f
$485c:  90           DB  $90
$485d:  91           DB  $91
$485e:  92           DB  $92
$485f:  93           DB  $93
$4860:  94           DB  $94
$4861:  95           DB  $95
$4862:  96           DB  $96
$4863:  97           DB  $97
$4864:  98           DB  $98
$4865:  99           DB  $99
$4866:  9a           DB  $9a
$4867:  9b           DB  $9b
$4868:  9c           DB  $9c
$4869:  9d           DB  $9d
$486a:  9e           DB  $9e
$486b:  9f           DB  $9f
$486c:  54           DB  $54
$486d:  00           DB  $00
$486e:  76           DB  $76
$486f:  00           DB  $00
$4870:  54           DB  $54
$4871:  00           DB  $00
$4872:  76           DB  $76
$4873:  00           DB  $00
$4874:  54           DB  $54
$4875:  00           DB  $00
$4876:  76           DB  $76
$4877:  00           DB  $00
$4878:  a8           DB  $a8
$4879:  00           DB  $00
$487a:  76           DB  $76
$487b:  00           DB  $00
$487c:  a8           DB  $a8
$487d:  00           DB  $00
$487e:  76           DB  $76
$487f:  00           DB  $00
$4880:  00           DB  $00
$4881:  00           DB  $00
$4882:  08           DB  $08
$4883:  08           DB  $08
$4884:  00           DB  $00
$4885:  00           DB  $00
$4886:  b0           DB  $b0
$4887:  05           DB  $05
$4888:  00           DB  $00
$4889:  00           DB  $00
$488a:  08           DB  $08
$488b:  08           DB  $08
$488c:  00           DB  $00
$488d:  00           DB  $00
$488e:  b0           DB  $b0
$488f:  05           DB  $05
$4890:  00           DB  $00
$4891:  00           DB  $00
$4892:  08           DB  $08
$4893:  08           DB  $08
$4894:  00           DB  $00
$4895:  00           DB  $00
$4896:  c1           DB  $c1
$4897:  89           DB  $89
$4898:  07           DB  $07
$4899:  0c           DB  $0c
$489a:  04           DB  $04
$489b:  0c           DB  $0c
$489c:  85           DB  $85
$489d:  89           DB  $89
$489e:  85           DB  $85
$489f:  89           DB  $89
$48a0:  04           DB  $04
$48a1:  c0           DB  $c0
$48a2:  02           DB  $02
$48a3:  85           DB  $85
$48a4:  40           DB  $40
$48a5:  02           DB  $02
$48a6:  01           DB  $01
$48a7:  c0           DB  $c0
$48a8:  0e           DB  $0e
$48a9:  82           DB  $82
$48aa:  40           DB  $40
$48ab:  0f           DB  $0f
$48ac:  83           DB  $83
$48ad:  10           DB  $10
$48ae:  82           DB  $82
$48af:  0f           DB  $0f
$48b0:  81           DB  $81
$48b1:  0e           DB  $0e
$48b2:  82           DB  $82
$48b3:  c0           DB  $c0
$48b4:  0e           DB  $0e
$48b5:  02           DB  $02
$48b6:  40           DB  $40
$48b7:  0f           DB  $0f
$48b8:  01           DB  $01
$48b9:  10           DB  $10
$48ba:  02           DB  $02
$48bb:  0f           DB  $0f
$48bc:  03           DB  $03
$48bd:  0e           DB  $0e
$48be:  02           DB  $02
$48bf:  c1           DB  $c1
$48c0:  89           DB  $89
$48c1:  08           DB  $08
$48c2:  0c           DB  $0c
$48c3:  88           DB  $88
$48c4:  0c           DB  $0c
$48c5:  86           DB  $86
$48c6:  89           DB  $89
$48c7:  86           DB  $86
$48c8:  c0           DB  $c0
$48c9:  02           DB  $02
$48ca:  86           DB  $86
$48cb:  40           DB  $40
$48cc:  02           DB  $02
$48cd:  02           DB  $02
$48ce:  01           DB  $01
$48cf:  04           DB  $04
$48d0:  81           DB  $81
$48d1:  05           DB  $05
$48d2:  86           DB  $86
$48d3:  05           DB  $05
$48d4:  88           DB  $88
$48d5:  04           DB  $04
$48d6:  89           DB  $89
$48d7:  02           DB  $02
$48d8:  89           DB  $89
$48d9:  86           DB  $86
$48da:  c1           DB  $c1
$48db:  89           DB  $89
$48dc:  07           DB  $07
$48dd:  82           DB  $82
$48de:  85           DB  $85
$48df:  82           DB  $82
$48e0:  04           DB  $04
$48e1:  02           DB  $02
$48e2:  04           DB  $04
$48e3:  04           DB  $04
$48e4:  03           DB  $03
$48e5:  05           DB  $05
$48e6:  01           DB  $01
$48e7:  05           DB  $05
$48e8:  82           DB  $82
$48e9:  04           DB  $04
$48ea:  84           DB  $84
$48eb:  02           DB  $02
$48ec:  85           DB  $85
$48ed:  86           DB  $86
$48ee:  85           DB  $85
$48ef:  88           DB  $88
$48f0:  84           DB  $84
$48f1:  89           DB  $89
$48f2:  82           DB  $82
$48f3:  89           DB  $89
$48f4:  04           DB  $04
$48f5:  c0           DB  $c0
$48f6:  07           DB  $07
$48f7:  82           DB  $82
$48f8:  40           DB  $40
$48f9:  08           DB  $08
$48fa:  83           DB  $83
$48fb:  09           DB  $09
$48fc:  82           DB  $82
$48fd:  08           DB  $08
$48fe:  81           DB  $81
$48ff:  07           DB  $07
$4900:  82           DB  $82
$4901:  c0           DB  $c0
$4902:  07           DB  $07
$4903:  02           DB  $02
$4904:  40           DB  $40
$4905:  08           DB  $08
$4906:  01           DB  $01
$4907:  09           DB  $09
$4908:  02           DB  $02
$4909:  08           DB  $08
$490a:  03           DB  $03
$490b:  07           DB  $07
$490c:  02           DB  $02
$490d:  c1           DB  $c1
$490e:  00           DB  $00
$490f:  00           DB  $00
$4910:  c1           DB  $c1
$4911:  89           DB  $89
$4912:  08           DB  $08
$4913:  c1           DB  $c1
$4914:  89           DB  $89
$4915:  04           DB  $04
$4916:  0c           DB  $0c
$4917:  00           DB  $00
$4918:  82           DB  $82
$4919:  00           DB  $00
$491a:  c0           DB  $c0
$491b:  87           DB  $87
$491c:  00           DB  $00
$491d:  40           DB  $40
$491e:  88           DB  $88
$491f:  81           DB  $81
$4920:  89           DB  $89
$4921:  00           DB  $00
$4922:  88           DB  $88
$4923:  01           DB  $01
$4924:  87           DB  $87
$4925:  00           DB  $00
$4926:  c1           DB  $c1
$4927:  89           DB  $89
$4928:  06           DB  $06
$4929:  0c           DB  $0c
$492a:  83           DB  $83
$492b:  07           DB  $07
$492c:  83           DB  $83
$492d:  0c           DB  $0c
$492e:  82           DB  $82
$492f:  0c           DB  $0c
$4930:  83           DB  $83
$4931:  c0           DB  $c0
$4932:  0c           DB  $0c
$4933:  02           DB  $02
$4934:  40           DB  $40
$4935:  07           DB  $07
$4936:  02           DB  $02
$4937:  0c           DB  $0c
$4938:  03           DB  $03
$4939:  0c           DB  $0c
$493a:  02           DB  $02
$493b:  c1           DB  $c1
$493c:  89           DB  $89
$493d:  0a           DB  $0a
$493e:  0e           DB  $0e
$493f:  01           DB  $01
$4940:  8b           DB  $8b
$4941:  85           DB  $85
$4942:  c0           DB  $c0
$4943:  0e           DB  $0e
$4944:  07           DB  $07
$4945:  40           DB  $40
$4946:  8b           DB  $8b
$4947:  01           DB  $01
$4948:  c0           DB  $c0
$4949:  03           DB  $03
$494a:  85           DB  $85
$494b:  40           DB  $40
$494c:  03           DB  $03
$494d:  07           DB  $07
$494e:  c0           DB  $c0
$494f:  82           DB  $82
$4950:  86           DB  $86
$4951:  40           DB  $40
$4952:  82           DB  $82
$4953:  06           DB  $06
$4954:  c1           DB  $c1
$4955:  89           DB  $89
$4956:  09           DB  $09
$4957:  04           DB  $04
$4958:  81           DB  $81
$4959:  03           DB  $03
$495a:  83           DB  $83
$495b:  01           DB  $01
$495c:  84           DB  $84
$495d:  81           DB  $81
$495e:  84           DB  $84
$495f:  83           DB  $83
$4960:  83           DB  $83
$4961:  84           DB  $84
$4962:  81           DB  $81
$4963:  84           DB  $84
$4964:  01           DB  $01
$4965:  83           DB  $83
$4966:  03           DB  $03
$4967:  81           DB  $81
$4968:  04           DB  $04
$4969:  01           DB  $01
$496a:  04           DB  $04
$496b:  03           DB  $03
$496c:  03           DB  $03
$496d:  04           DB  $04
$496e:  01           DB  $01
$496f:  04           DB  $04
$4970:  81           DB  $81
$4971:  c0           DB  $c0
$4972:  03           DB  $03
$4973:  83           DB  $83
$4974:  40           DB  $40
$4975:  07           DB  $07
$4976:  86           DB  $86
$4977:  c0           DB  $c0
$4978:  03           DB  $03
$4979:  03           DB  $03
$497a:  40           DB  $40
$497b:  07           DB  $07
$497c:  06           DB  $06
$497d:  c0           DB  $c0
$497e:  83           DB  $83
$497f:  83           DB  $83
$4980:  40           DB  $40
$4981:  87           DB  $87
$4982:  86           DB  $86
$4983:  c0           DB  $c0
$4984:  83           DB  $83
$4985:  03           DB  $03
$4986:  40           DB  $40
$4987:  87           DB  $87
$4988:  06           DB  $06
$4989:  c1           DB  $c1
$498a:  89           DB  $89
$498b:  0e           DB  $0e
$498c:  0c           DB  $0c
$498d:  07           DB  $07
$498e:  89           DB  $89
$498f:  87           DB  $87
$4990:  c0           DB  $c0
$4991:  09           DB  $09
$4992:  8b           DB  $8b
$4993:  40           DB  $40
$4994:  07           DB  $07
$4995:  8b           DB  $8b
$4996:  05           DB  $05
$4997:  8a           DB  $8a
$4998:  04           DB  $04
$4999:  88           DB  $88
$499a:  04           DB  $04
$499b:  86           DB  $86
$499c:  05           DB  $05
$499d:  84           DB  $84
$499e:  07           DB  $07
$499f:  83           DB  $83
$49a0:  09           DB  $09
$49a1:  83           DB  $83
$49a2:  0b           DB  $0b
$49a3:  84           DB  $84
$49a4:  0c           DB  $0c
$49a5:  86           DB  $86
$49a6:  0c           DB  $0c
$49a7:  88           DB  $88
$49a8:  0b           DB  $0b
$49a9:  8a           DB  $8a
$49aa:  09           DB  $09
$49ab:  8b           DB  $8b
$49ac:  c0           DB  $c0
$49ad:  84           DB  $84
$49ae:  03           DB  $03
$49af:  40           DB  $40
$49b0:  86           DB  $86
$49b1:  03           DB  $03
$49b2:  88           DB  $88
$49b3:  04           DB  $04
$49b4:  89           DB  $89
$49b5:  06           DB  $06
$49b6:  89           DB  $89
$49b7:  08           DB  $08
$49b8:  88           DB  $88
$49b9:  0a           DB  $0a
$49ba:  86           DB  $86
$49bb:  0b           DB  $0b
$49bc:  84           DB  $84
$49bd:  0b           DB  $0b
$49be:  82           DB  $82
$49bf:  0a           DB  $0a
$49c0:  81           DB  $81
$49c1:  08           DB  $08
$49c2:  81           DB  $81
$49c3:  06           DB  $06
$49c4:  82           DB  $82
$49c5:  04           DB  $04
$49c6:  84           DB  $84
$49c7:  03           DB  $03
$49c8:  c1           DB  $c1
$49c9:  89           DB  $89
$49ca:  09           DB  $09
$49cb:  89           DB  $89
$49cc:  07           DB  $07
$49cd:  07           DB  $07
$49ce:  85           DB  $85
$49cf:  09           DB  $09
$49d0:  85           DB  $85
$49d1:  0b           DB  $0b
$49d2:  84           DB  $84
$49d3:  0c           DB  $0c
$49d4:  82           DB  $82
$49d5:  0c           DB  $0c
$49d6:  81           DB  $81
$49d7:  0b           DB  $0b
$49d8:  01           DB  $01
$49d9:  09           DB  $09
$49da:  02           DB  $02
$49db:  07           DB  $07
$49dc:  02           DB  $02
$49dd:  04           DB  $04
$49de:  81           DB  $81
$49df:  02           DB  $02
$49e0:  84           DB  $84
$49e1:  81           DB  $81
$49e2:  87           DB  $87
$49e3:  84           DB  $84
$49e4:  88           DB  $88
$49e5:  86           DB  $86
$49e6:  88           DB  $88
$49e7:  88           DB  $88
$49e8:  87           DB  $87
$49e9:  89           DB  $89
$49ea:  85           DB  $85
$49eb:  89           DB  $89
$49ec:  81           DB  $81
$49ed:  88           DB  $88
$49ee:  01           DB  $01
$49ef:  82           DB  $82
$49f0:  07           DB  $07
$49f1:  c1           DB  $c1
$49f2:  89           DB  $89
$49f3:  03           DB  $03
$49f4:  0c           DB  $0c
$49f5:  00           DB  $00
$49f6:  07           DB  $07
$49f7:  00           DB  $00
$49f8:  0c           DB  $0c
$49f9:  01           DB  $01
$49fa:  0c           DB  $0c
$49fb:  00           DB  $00
$49fc:  c1           DB  $c1
$49fd:  89           DB  $89
$49fe:  06           DB  $06
$49ff:  0f           DB  $0f
$4a00:  02           DB  $02
$4a01:  0b           DB  $0b
$4a02:  00           DB  $00
$4a03:  04           DB  $04
$4a04:  82           DB  $82
$4a05:  00           DB  $00
$4a06:  82           DB  $82
$4a07:  84           DB  $84
$4a08:  81           DB  $81
$4a09:  8b           DB  $8b
$4a0a:  02           DB  $02
$4a0b:  c1           DB  $c1
$4a0c:  89           DB  $89
$4a0d:  05           DB  $05
$4a0e:  0f           DB  $0f
$4a0f:  82           DB  $82
$4a10:  0b           DB  $0b
$4a11:  00           DB  $00
$4a12:  04           DB  $04
$4a13:  02           DB  $02
$4a14:  00           DB  $00
$4a15:  02           DB  $02
$4a16:  84           DB  $84
$4a17:  01           DB  $01
$4a18:  8b           DB  $8b
$4a19:  82           DB  $82
$4a1a:  c1           DB  $c1
$4a1b:  89           DB  $89
$4a1c:  08           DB  $08
$4a1d:  00           DB  $00
$4a1e:  85           DB  $85
$4a1f:  00           DB  $00
$4a20:  05           DB  $05
$4a21:  c0           DB  $c0
$4a22:  05           DB  $05
$4a23:  83           DB  $83
$4a24:  40           DB  $40
$4a25:  85           DB  $85
$4a26:  03           DB  $03
$4a27:  c0           DB  $c0
$4a28:  05           DB  $05
$4a29:  03           DB  $03
$4a2a:  40           DB  $40
$4a2b:  85           DB  $85
$4a2c:  83           DB  $83
$4a2d:  c1           DB  $c1
$4a2e:  89           DB  $89
$4a2f:  08           DB  $08
$4a30:  05           DB  $05
$4a31:  00           DB  $00
$4a32:  85           DB  $85
$4a33:  00           DB  $00
$4a34:  c0           DB  $c0
$4a35:  00           DB  $00
$4a36:  85           DB  $85
$4a37:  40           DB  $40
$4a38:  00           DB  $00
$4a39:  05           DB  $05
$4a3a:  c1           DB  $c1
$4a3b:  89           DB  $89
$4a3c:  04           DB  $04
$4a3d:  88           DB  $88
$4a3e:  01           DB  $01
$4a3f:  89           DB  $89
$4a40:  01           DB  $01
$4a41:  88           DB  $88
$4a42:  81           DB  $81
$4a43:  87           DB  $87
$4a44:  00           DB  $00
$4a45:  88           DB  $88
$4a46:  01           DB  $01
$4a47:  8a           DB  $8a
$4a48:  01           DB  $01
$4a49:  8c           DB  $8c
$4a4a:  00           DB  $00
$4a4b:  8d           DB  $8d
$4a4c:  81           DB  $81
$4a4d:  c1           DB  $c1
$4a4e:  89           DB  $89
$4a4f:  08           DB  $08
$4a50:  00           DB  $00
$4a51:  85           DB  $85
$4a52:  00           DB  $00
$4a53:  05           DB  $05
$4a54:  c1           DB  $c1
$4a55:  89           DB  $89
$4a56:  04           DB  $04
$4a57:  87           DB  $87
$4a58:  00           DB  $00
$4a59:  88           DB  $88
$4a5a:  81           DB  $81
$4a5b:  89           DB  $89
$4a5c:  00           DB  $00
$4a5d:  88           DB  $88
$4a5e:  01           DB  $01
$4a5f:  87           DB  $87
$4a60:  00           DB  $00
$4a61:  c1           DB  $c1
$4a62:  89           DB  $89
$4a63:  0a           DB  $0a
$4a64:  10           DB  $10
$4a65:  07           DB  $07
$4a66:  8e           DB  $8e
$4a67:  87           DB  $87
$4a68:  c1           DB  $c1
$4a69:  89           DB  $89
$4a6a:  08           DB  $08
$4a6b:  0c           DB  $0c
$4a6c:  83           DB  $83
$4a6d:  0b           DB  $0b
$4a6e:  85           DB  $85
$4a6f:  09           DB  $09
$4a70:  86           DB  $86
$4a71:  86           DB  $86
$4a72:  86           DB  $86
$4a73:  88           DB  $88
$4a74:  85           DB  $85
$4a75:  89           DB  $89
$4a76:  83           DB  $83
$4a77:  89           DB  $89
$4a78:  02           DB  $02
$4a79:  88           DB  $88
$4a7a:  04           DB  $04
$4a7b:  86           DB  $86
$4a7c:  05           DB  $05
$4a7d:  09           DB  $09
$4a7e:  05           DB  $05
$4a7f:  0b           DB  $0b
$4a80:  04           DB  $04
$4a81:  0c           DB  $0c
$4a82:  02           DB  $02
$4a83:  0c           DB  $0c
$4a84:  83           DB  $83
$4a85:  c1           DB  $c1
$4a86:  89           DB  $89
$4a87:  06           DB  $06
$4a88:  04           DB  $04
$4a89:  83           DB  $83
$4a8a:  0c           DB  $0c
$4a8b:  03           DB  $03
$4a8c:  89           DB  $89
$4a8d:  03           DB  $03
$4a8e:  c1           DB  $c1
$4a8f:  89           DB  $89
$4a90:  08           DB  $08
$4a91:  08           DB  $08
$4a92:  86           DB  $86
$4a93:  0a           DB  $0a
$4a94:  85           DB  $85
$4a95:  0c           DB  $0c
$4a96:  83           DB  $83
$4a97:  0c           DB  $0c
$4a98:  02           DB  $02
$4a99:  0b           DB  $0b
$4a9a:  04           DB  $04
$4a9b:  09           DB  $09
$4a9c:  05           DB  $05
$4a9d:  05           DB  $05
$4a9e:  05           DB  $05
$4a9f:  89           DB  $89
$4aa0:  86           DB  $86
$4aa1:  89           DB  $89
$4aa2:  05           DB  $05
$4aa3:  c1           DB  $c1
$4aa4:  89           DB  $89
$4aa5:  07           DB  $07
$4aa6:  0c           DB  $0c
$4aa7:  85           DB  $85
$4aa8:  0c           DB  $0c
$4aa9:  04           DB  $04
$4aaa:  03           DB  $03
$4aab:  81           DB  $81
$4aac:  03           DB  $03
$4aad:  01           DB  $01
$4aae:  02           DB  $02
$4aaf:  03           DB  $03
$4ab0:  00           DB  $00
$4ab1:  04           DB  $04
$4ab2:  86           DB  $86
$4ab3:  04           DB  $04
$4ab4:  88           DB  $88
$4ab5:  03           DB  $03
$4ab6:  89           DB  $89
$4ab7:  01           DB  $01
$4ab8:  89           DB  $89
$4ab9:  85           DB  $85
$4aba:  c1           DB  $c1
$4abb:  89           DB  $89
$4abc:  08           DB  $08
$4abd:  0c           DB  $0c
$4abe:  82           DB  $82
$4abf:  83           DB  $83
$4ac0:  86           DB  $86
$4ac1:  83           DB  $83
$4ac2:  05           DB  $05
$4ac3:  c0           DB  $c0
$4ac4:  03           DB  $03
$4ac5:  02           DB  $02
$4ac6:  40           DB  $40
$4ac7:  89           DB  $89
$4ac8:  02           DB  $02
$4ac9:  c1           DB  $c1
$4aca:  89           DB  $89
$4acb:  07           DB  $07
$4acc:  0c           DB  $0c
$4acd:  04           DB  $04
$4ace:  0c           DB  $0c
$4acf:  85           DB  $85
$4ad0:  02           DB  $02
$4ad1:  85           DB  $85
$4ad2:  02           DB  $02
$4ad3:  01           DB  $01
$4ad4:  01           DB  $01
$4ad5:  03           DB  $03
$4ad6:  81           DB  $81
$4ad7:  04           DB  $04
$4ad8:  86           DB  $86
$4ad9:  04           DB  $04
$4ada:  88           DB  $88
$4adb:  03           DB  $03
$4adc:  89           DB  $89
$4add:  01           DB  $01
$4ade:  89           DB  $89
$4adf:  85           DB  $85
$4ae0:  c1           DB  $c1
$4ae1:  89           DB  $89
$4ae2:  08           DB  $08
$4ae3:  0c           DB  $0c
$4ae4:  02           DB  $02
$4ae5:  0c           DB  $0c
$4ae6:  01           DB  $01
$4ae7:  0b           DB  $0b
$4ae8:  82           DB  $82
$4ae9:  09           DB  $09
$4aea:  84           DB  $84
$4aeb:  07           DB  $07
$4aec:  85           DB  $85
$4aed:  03           DB  $03
$4aee:  86           DB  $86
$4aef:  86           DB  $86
$4af0:  86           DB  $86
$4af1:  88           DB  $88
$4af2:  85           DB  $85
$4af3:  89           DB  $89
$4af4:  83           DB  $83
$4af5:  89           DB  $89
$4af6:  02           DB  $02
$4af7:  88           DB  $88
$4af8:  04           DB  $04
$4af9:  86           DB  $86
$4afa:  05           DB  $05
$4afb:  81           DB  $81
$4afc:  05           DB  $05
$4afd:  01           DB  $01
$4afe:  04           DB  $04
$4aff:  02           DB  $02
$4b00:  02           DB  $02
$4b01:  02           DB  $02
$4b02:  86           DB  $86
$4b03:  c1           DB  $c1
$4b04:  89           DB  $89
$4b05:  08           DB  $08
$4b06:  09           DB  $09
$4b07:  86           DB  $86
$4b08:  0c           DB  $0c
$4b09:  86           DB  $86
$4b0a:  0c           DB  $0c
$4b0b:  05           DB  $05
$4b0c:  89           DB  $89
$4b0d:  81           DB  $81
$4b0e:  c1           DB  $c1
$4b0f:  89           DB  $89
$4b10:  08           DB  $08
$4b11:  03           DB  $03
$4b12:  01           DB  $01
$4b13:  04           DB  $04
$4b14:  03           DB  $03
$4b15:  06           DB  $06
$4b16:  04           DB  $04
$4b17:  09           DB  $09
$4b18:  04           DB  $04
$4b19:  0b           DB  $0b
$4b1a:  03           DB  $03
$4b1b:  0c           DB  $0c
$4b1c:  01           DB  $01
$4b1d:  0c           DB  $0c
$4b1e:  82           DB  $82
$4b1f:  0b           DB  $0b
$4b20:  84           DB  $84
$4b21:  09           DB  $09
$4b22:  85           DB  $85
$4b23:  06           DB  $06
$4b24:  85           DB  $85
$4b25:  04           DB  $04
$4b26:  84           DB  $84
$4b27:  03           DB  $03
$4b28:  82           DB  $82
$4b29:  02           DB  $02
$4b2a:  84           DB  $84
$4b2b:  81           DB  $81
$4b2c:  86           DB  $86
$4b2d:  86           DB  $86
$4b2e:  86           DB  $86
$4b2f:  88           DB  $88
$4b30:  84           DB  $84
$4b31:  89           DB  $89
$4b32:  82           DB  $82
$4b33:  89           DB  $89
$4b34:  01           DB  $01
$4b35:  88           DB  $88
$4b36:  03           DB  $03
$4b37:  86           DB  $86
$4b38:  05           DB  $05
$4b39:  81           DB  $81
$4b3a:  05           DB  $05
$4b3b:  02           DB  $02
$4b3c:  03           DB  $03
$4b3d:  03           DB  $03
$4b3e:  01           DB  $01
$4b3f:  03           DB  $03
$4b40:  82           DB  $82
$4b41:  c1           DB  $c1
$4b42:  89           DB  $89
$4b43:  08           DB  $08
$4b44:  89           DB  $89
$4b45:  83           DB  $83
$4b46:  89           DB  $89
$4b47:  82           DB  $82
$4b48:  88           DB  $88
$4b49:  01           DB  $01
$4b4a:  87           DB  $87
$4b4b:  03           DB  $03
$4b4c:  84           DB  $84
$4b4d:  04           DB  $04
$4b4e:  00           DB  $00
$4b4f:  05           DB  $05
$4b50:  03           DB  $03
$4b51:  05           DB  $05
$4b52:  0b           DB  $0b
$4b53:  04           DB  $04
$4b54:  0c           DB  $0c
$4b55:  02           DB  $02
$4b56:  0c           DB  $0c
$4b57:  83           DB  $83
$4b58:  0b           DB  $0b
$4b59:  85           DB  $85
$4b5a:  09           DB  $09
$4b5b:  86           DB  $86
$4b5c:  04           DB  $04
$4b5d:  86           DB  $86
$4b5e:  02           DB  $02
$4b5f:  85           DB  $85
$4b60:  01           DB  $01
$4b61:  83           DB  $83
$4b62:  01           DB  $01
$4b63:  05           DB  $05
$4b64:  c1           DB  $c1
$4b65:  89           DB  $89
$4b66:  04           DB  $04
$4b67:  87           DB  $87
$4b68:  00           DB  $00
$4b69:  88           DB  $88
$4b6a:  81           DB  $81
$4b6b:  89           DB  $89
$4b6c:  00           DB  $00
$4b6d:  88           DB  $88
$4b6e:  01           DB  $01
$4b6f:  87           DB  $87
$4b70:  00           DB  $00
$4b71:  c0           DB  $c0
$4b72:  05           DB  $05
$4b73:  00           DB  $00
$4b74:  40           DB  $40
$4b75:  04           DB  $04
$4b76:  81           DB  $81
$4b77:  03           DB  $03
$4b78:  00           DB  $00
$4b79:  04           DB  $04
$4b7a:  01           DB  $01
$4b7b:  05           DB  $05
$4b7c:  00           DB  $00
$4b7d:  c1           DB  $c1
$4b7e:  89           DB  $89
$4b7f:  04           DB  $04
$4b80:  88           DB  $88
$4b81:  01           DB  $01
$4b82:  89           DB  $89
$4b83:  00           DB  $00
$4b84:  88           DB  $88
$4b85:  81           DB  $81
$4b86:  87           DB  $87
$4b87:  00           DB  $00
$4b88:  88           DB  $88
$4b89:  01           DB  $01
$4b8a:  8a           DB  $8a
$4b8b:  01           DB  $01
$4b8c:  8c           DB  $8c
$4b8d:  00           DB  $00
$4b8e:  8d           DB  $8d
$4b8f:  81           DB  $81
$4b90:  c0           DB  $c0
$4b91:  05           DB  $05
$4b92:  00           DB  $00
$4b93:  40           DB  $40
$4b94:  04           DB  $04
$4b95:  81           DB  $81
$4b96:  03           DB  $03
$4b97:  00           DB  $00
$4b98:  04           DB  $04
$4b99:  01           DB  $01
$4b9a:  05           DB  $05
$4b9b:  00           DB  $00
$4b9c:  c1           DB  $c1
$4b9d:  89           DB  $89
$4b9e:  08           DB  $08
$4b9f:  05           DB  $05
$4ba0:  05           DB  $05
$4ba1:  00           DB  $00
$4ba2:  85           DB  $85
$4ba3:  85           DB  $85
$4ba4:  05           DB  $05
$4ba5:  c1           DB  $c1
$4ba6:  89           DB  $89
$4ba7:  08           DB  $08
$4ba8:  02           DB  $02
$4ba9:  85           DB  $85
$4baa:  02           DB  $02
$4bab:  05           DB  $05
$4bac:  c0           DB  $c0
$4bad:  83           DB  $83
$4bae:  85           DB  $85
$4baf:  40           DB  $40
$4bb0:  83           DB  $83
$4bb1:  05           DB  $05
$4bb2:  c1           DB  $c1
$4bb3:  89           DB  $89
$4bb4:  08           DB  $08
$4bb5:  05           DB  $05
$4bb6:  85           DB  $85
$4bb7:  00           DB  $00
$4bb8:  05           DB  $05
$4bb9:  85           DB  $85
$4bba:  85           DB  $85
$4bbb:  c1           DB  $c1
$4bbc:  89           DB  $89
$4bbd:  08           DB  $08
$4bbe:  07           DB  $07
$4bbf:  85           DB  $85
$4bc0:  08           DB  $08
$4bc1:  85           DB  $85
$4bc2:  0a           DB  $0a
$4bc3:  84           DB  $84
$4bc4:  0c           DB  $0c
$4bc5:  82           DB  $82
$4bc6:  0c           DB  $0c
$4bc7:  02           DB  $02
$4bc8:  0a           DB  $0a
$4bc9:  04           DB  $04
$4bca:  08           DB  $08
$4bcb:  05           DB  $05
$4bcc:  06           DB  $06
$4bcd:  05           DB  $05
$4bce:  04           DB  $04
$4bcf:  04           DB  $04
$4bd0:  02           DB  $02
$4bd1:  02           DB  $02
$4bd2:  01           DB  $01
$4bd3:  00           DB  $00
$4bd4:  82           DB  $82
$4bd5:  00           DB  $00
$4bd6:  c0           DB  $c0
$4bd7:  87           DB  $87
$4bd8:  00           DB  $00
$4bd9:  40           DB  $40
$4bda:  88           DB  $88
$4bdb:  81           DB  $81
$4bdc:  89           DB  $89
$4bdd:  00           DB  $00
$4bde:  88           DB  $88
$4bdf:  01           DB  $01
$4be0:  87           DB  $87
$4be1:  00           DB  $00
$4be2:  c1           DB  $c1
$4be3:  89           DB  $89
$4be4:  08           DB  $08
$4be5:  05           DB  $05
$4be6:  85           DB  $85
$4be7:  89           DB  $89
$4be8:  85           DB  $85
$4be9:  c0           DB  $c0
$4bea:  82           DB  $82
$4beb:  85           DB  $85
$4bec:  40           DB  $40
$4bed:  82           DB  $82
$4bee:  82           DB  $82
$4bef:  86           DB  $86
$4bf0:  82           DB  $82
$4bf1:  88           DB  $88
$4bf2:  81           DB  $81
$4bf3:  89           DB  $89
$4bf4:  00           DB  $00
$4bf5:  89           DB  $89
$4bf6:  03           DB  $03
$4bf7:  88           DB  $88
$4bf8:  04           DB  $04
$4bf9:  86           DB  $86
$4bfa:  05           DB  $05
$4bfb:  02           DB  $02
$4bfc:  05           DB  $05
$4bfd:  04           DB  $04
$4bfe:  04           DB  $04
$4bff:  05           DB  $05
$4c00:  03           DB  $03
$4c01:  05           DB  $05
$4c02:  00           DB  $00
$4c03:  04           DB  $04
$4c04:  81           DB  $81
$4c05:  02           DB  $02
$4c06:  82           DB  $82
$4c07:  82           DB  $82
$4c08:  82           DB  $82
$4c09:  c1           DB  $c1
$4c0a:  89           DB  $89
$4c0b:  08           DB  $08
$4c0c:  88           DB  $88
$4c0d:  03           DB  $03
$4c0e:  05           DB  $05
$4c0f:  03           DB  $03
$4c10:  05           DB  $05
$4c11:  82           DB  $82
$4c12:  04           DB  $04
$4c13:  84           DB  $84
$4c14:  02           DB  $02
$4c15:  85           DB  $85
$4c16:  86           DB  $86
$4c17:  85           DB  $85
$4c18:  88           DB  $88
$4c19:  84           DB  $84
$4c1a:  89           DB  $89
$4c1b:  82           DB  $82
$4c1c:  89           DB  $89
$4c1d:  02           DB  $02
$4c1e:  88           DB  $88
$4c1f:  03           DB  $03
$4c20:  89           DB  $89
$4c21:  04           DB  $04
$4c22:  89           DB  $89
$4c23:  05           DB  $05
$4c24:  c1           DB  $c1
$4c25:  89           DB  $89
$4c26:  07           DB  $07
$4c27:  05           DB  $05
$4c28:  01           DB  $01
$4c29:  05           DB  $05
$4c2a:  82           DB  $82
$4c2b:  04           DB  $04
$4c2c:  84           DB  $84
$4c2d:  02           DB  $02
$4c2e:  85           DB  $85
$4c2f:  86           DB  $86
$4c30:  85           DB  $85
$4c31:  88           DB  $88
$4c32:  84           DB  $84
$4c33:  89           DB  $89
$4c34:  82           DB  $82
$4c35:  89           DB  $89
$4c36:  01           DB  $01
$4c37:  88           DB  $88
$4c38:  03           DB  $03
$4c39:  86           DB  $86
$4c3a:  04           DB  $04
$4c3b:  02           DB  $02
$4c3c:  04           DB  $04
$4c3d:  0c           DB  $0c
$4c3e:  85           DB  $85
$4c3f:  0c           DB  $0c
$4c40:  04           DB  $04
$4c41:  c1           DB  $c1
$4c42:  89           DB  $89
$4c43:  08           DB  $08
$4c44:  05           DB  $05
$4c45:  85           DB  $85
$4c46:  86           DB  $86

F_P_4c47:
$4c47:  85                  ADD      L
$4c48:  88                  ADC      B
$4c49:  84                  ADD      H
$4c4a:  89                  ADC      C
$4c4b:  82                  ADD      D
$4c4c:  89                  ADC      C
$4c4d:  05                  DCR      B
$4c4e:  8c                  ADC      H
$4c4f:  05                  DCR      B
$4c50:  c0                  RNZ
$4c51:  05                  DCR      B
$4c52:  03                  INX      B
$4c53:  40                  NOP
$4c54:  89                  ADC      C
$4c55:  03                  INX      B
$4c56:  c1                  POP      B
$4c57:  89                  ADC      C
$4c58:  07                  RLC
$4c59:  05                  DCR      B
$4c5a:  04                  INR      B
$4c5b:  05                  DCR      B
$4c5c:  82                  ADD      D
$4c5d:  04                  INR      B
$4c5e:  84                  ADD      H
$4c5f:  02                  STAX     B
$4c60:  85                  ADD      L
$4c61:  86                  ADD      M
$4c62:  85                  ADD      L
$4c63:  88                  ADC      B
$4c64:  84                  ADD      H
$4c65:  89                  ADC      C
$4c66:  82                  ADD      D
$4c67:  89                  ADC      C
$4c68:  01 88 03            LXI      B,$0388
$4c6b:  86                  ADD      M
$4c6c:  04                  INR      B
$4c6d:  09                  DAD      B
$4c6e:  04                  INR      B
$4c6f:  0b                  DCX      B
$4c70:  03                  INX      B
$4c71:  0c                  INR      C
$4c72:  01 0c 83            LXI      B,$830c
$4c75:  c1                  POP      B
$4c76:  89                  ADC      C
$4c77:  07                  RLC
$4c78:  82                  ADD      D
$4c79:  85                  ADD      L
$4c7a:  82                  ADD      D
$4c7b:  04                  INR      B
$4c7c:  02                  STAX     B
$4c7d:  04                  INR      B
$4c7e:  04                  INR      B
$4c7f:  03                  INX      B
$4c80:  05                  DCR      B
$4c81:  01 05 82            LXI      B,$8205
$4c84:  04                  INR      B
$4c85:  84                  ADD      H
$4c86:  02                  STAX     B
$4c87:  85                  ADD      L
$4c88:  86                  ADD      M
$4c89:  85                  ADD      L
$4c8a:  88                  ADC      B
$4c8b:  84                  ADD      H
$4c8c:  89                  ADC      C
$4c8d:  82                  ADD      D
$4c8e:  89                  ADC      C
$4c8f:  04                  INR      B
$4c90:  c1                  POP      B
$4c91:  89                  ADC      C
$4c92:  09                  DAD      B
$4c93:  09                  DAD      B
$4c94:  00                  NOP
$4c95:  90                  SUB      B
$4c96:  00                  NOP
$4c97:  c0                  RNZ
$4c98:  05                  DCR      B
$4c99:  83                  ADD      E
$4c9a:  40                  NOP
$4c9b:  04                  INR      B
$4c9c:  85                  ADD      L
$4c9d:  02                  STAX     B
$4c9e:  86                  ADD      M
$4c9f:  86                  ADD      M
$4ca0:  86                  ADD      M
$4ca1:  88                  ADC      B
$4ca2:  85                  ADD      L
$4ca3:  89                  ADC      C
$4ca4:  83                  ADD      E
$4ca5:  89                  ADC      C
$4ca6:  03                  INX      B
$4ca7:  88                  ADC      B
$4ca8:  05                  DCR      B
$4ca9:  86                  ADD      M
$4caa:  06 02               MVI      B,$02
$4cac:  06 04               MVI      B,$04
$4cae:  05                  DCR      B
$4caf:  05                  DCR      B
$4cb0:  03                  INX      B
$4cb1:  05                  DCR      B
$4cb2:  83                  ADD      E
$4cb3:  c1                  POP      B
$4cb4:  89                  ADC      C
$4cb5:  07                  RLC
$4cb6:  03                  INX      B
$4cb7:  85                  ADD      L
$4cb8:  04                  INR      B
$4cb9:  84                  ADD      H
$4cba:  05                  DCR      B
$4cbb:  82                  ADD      D
$4cbc:  05                  DCR      B
$4cbd:  01 04 03            LXI      B,$0304
$4cc0:  02                  STAX     B
$4cc1:  04                  INR      B
$4cc2:  00                  NOP
$4cc3:  03                  INX      B
$4cc4:  84                  ADD      H
$4cc5:  84                  ADD      H
$4cc6:  86                  ADD      M
$4cc7:  85                  ADD      L
$4cc8:  88                  ADC      B
$4cc9:  84                  ADD      H
$4cca:  89                  ADC      C
$4ccb:  82                  ADD      D
$4ccc:  89                  ADC      C
$4ccd:  01 88 03            LXI      B,$0388
$4cd0:  87                  ADD      A
$4cd1:  04                  INR      B
$4cd2:  c1                  POP      B
$4cd3:  89                  ADC      C
$4cd4:  07                  RLC
$4cd5:  05                  DCR      B
$4cd6:  85                  ADD      L
$4cd7:  89                  ADC      C
$4cd8:  04                  INR      B
$4cd9:  c0                  RNZ
$4cda:  05                  DCR      B
$4cdb:  04                  INR      B
$4cdc:  40                  NOP
$4cdd:  89                  ADC      C
$4cde:  85                  ADD      L
$4cdf:  c1                  POP      B
$4ce0:  89                  ADC      C
$4ce1:  07                  RLC
$4ce2:  05                  DCR      B
$4ce3:  85                  ADD      L
$4ce4:  86                  ADD      M
$4ce5:  85                  ADD      L
$4ce6:  88                  ADC      B
$4ce7:  84                  ADD      H
$4ce8:  89                  ADC      C
$4ce9:  82                  ADD      D
$4cea:  89                  ADC      C
$4ceb:  04                  INR      B
$4cec:  05                  DCR      B
$4ced:  04                  INR      B
$4cee:  c1                  POP      B
$4cef:  89                  ADC      C
$4cf0:  07                  RLC
$4cf1:  05                  DCR      B
$4cf2:  85                  ADD      L
$4cf3:  86                  ADD      M
$4cf4:  85                  ADD      L
$4cf5:  88                  ADC      B
$4cf6:  84                  ADD      H
$4cf7:  89                  ADC      C
$4cf8:  82                  ADD      D
$4cf9:  89                  ADC      C
$4cfa:  04                  INR      B
$4cfb:  05                  DCR      B
$4cfc:  04                  INR      B
$4cfd:  c0                  RNZ
$4cfe:  0b                  DCX      B
$4cff:  83                  ADD      E
$4d00:  40                  NOP
$4d01:  0b                  DCX      B
$4d02:  03                  INX      B
$4d03:  c1                  POP      B
$4d04:  89                  ADC      C
$4d05:  08                  NOP
$4d06:  05                  DCR      B
$4d07:  85                  ADD      L
$4d08:  89                  ADC      C
$4d09:  85                  ADD      L
$4d0a:  c0                  RNZ
$4d0b:  83                  ADD      E
$4d0c:  85                  ADD      L
$4d0d:  40                  NOP
$4d0e:  05                  DCR      B
$4d0f:  05                  DCR      B
$4d10:  c0                  RNZ
$4d11:  81                  ADD      C
$4d12:  82                  ADD      D
$4d13:  40                  NOP
$4d14:  89                  ADC      C
$4d15:  05                  DCR      B
$4d16:  c1                  POP      B
$4d17:  89                  ADC      C
$4d18:  07                  RLC
$4d19:  89                  ADC      C
$4d1a:  85                  ADD      L
$4d1b:  05                  DCR      B
$4d1c:  81                  ADD      C
$4d1d:  05                  DCR      B
$4d1e:  04                  INR      B
$4d1f:  89                  ADC      C
$4d20:  04                  INR      B
$4d21:  c1                  POP      B
$4d22:  89                  ADC      C
$4d23:  08                  NOP
$4d24:  89                  ADC      C
$4d25:  85                  ADD      L
$4d26:  05                  DCR      B
$4d27:  85                  ADD      L
$4d28:  88                  ADC      B
$4d29:  00                  NOP
$4d2a:  05                  DCR      B
$4d2b:  05                  DCR      B
$4d2c:  89                  ADC      C
$4d2d:  05                  DCR      B
$4d2e:  c1                  POP      B
$4d2f:  89                  ADC      C
$4d30:  07                  RLC
$4d31:  05                  DCR      B
$4d32:  85                  ADD      L
$4d33:  89                  ADC      C
$4d34:  85                  ADD      L
$4d35:  c0                  RNZ
$4d36:  05                  DCR      B
$4d37:  04                  INR      B
$4d38:  40                  NOP
$4d39:  89                  ADC      C
$4d3a:  04                  INR      B
$4d3b:  c0                  RNZ
$4d3c:  82                  ADD      D
$4d3d:  85                  ADD      L
$4d3e:  40                  NOP
$4d3f:  82                  ADD      D
$4d40:  04                  INR      B
$4d41:  c1                  POP      B
$4d42:  89                  ADC      C
$4d43:  07                  RLC
$4d44:  05                  DCR      B
$4d45:  82                  ADD      D
$4d46:  04                  INR      B
$4d47:  84                  ADD      H
$4d48:  02                  STAX     B
$4d49:  85                  ADD      L
$4d4a:  86                  ADD      M
$4d4b:  85                  ADD      L
$4d4c:  88                  ADC      B
$4d4d:  84                  ADD      H
$4d4e:  89                  ADC      C
$4d4f:  82                  ADD      D
$4d50:  89                  ADC      C
$4d51:  01 88 03            LXI      B,$0388
$4d54:  86                  ADD      M
$4d55:  04                  INR      B
$4d56:  02                  STAX     B
$4d57:  04                  INR      B
$4d58:  04                  INR      B
$4d59:  03                  INX      B
$4d5a:  05                  DCR      B
$4d5b:  01 05 82            LXI      B,$8205
$4d5e:  c1                  POP      B
$4d5f:  89                  ADC      C
$4d60:  07                  RLC
$4d61:  89                  ADC      C
$4d62:  85                  ADD      L
$4d63:  05                  DCR      B
$4d64:  85                  ADD      L
$4d65:  05                  DCR      B
$4d66:  01 04 03            LXI      B,$0304
$4d69:  02                  STAX     B
$4d6a:  04                  INR      B
$4d6b:  89                  ADC      C
$4d6c:  04                  INR      B
$4d6d:  c1                  POP      B
$4d6e:  89                  ADC      C
$4d6f:  07                  RLC
$4d70:  05                  DCR      B
$4d71:  04                  INR      B
$4d72:  89                  ADC      C
$4d73:  04                  INR      B
$4d74:  c0                  RNZ
$4d75:  05                  DCR      B
$4d76:  04                  INR      B
$4d77:  40                  NOP
$4d78:  05                  DCR      B
$4d79:  82                  ADD      D
$4d7a:  04                  INR      B
$4d7b:  84                  ADD      H
$4d7c:  02                  STAX     B
$4d7d:  85                  ADD      L
$4d7e:  00                  NOP
$4d7f:  85                  ADD      L
$4d80:  82                  ADD      D
$4d81:  84                  ADD      H
$4d82:  83                  ADD      E
$4d83:  82                  ADD      D
$4d84:  83                  ADD      E
$4d85:  04                  INR      B
$4d86:  c0                  RNZ
$4d87:  83                  ADD      E
$4d88:  81                  ADD      C
$4d89:  40                  NOP
$4d8a:  89                  ADC      C
$4d8b:  85                  ADD      L
$4d8c:  c1                  POP      B
$4d8d:  89                  ADC      C
$4d8e:  07                  RLC
$4d8f:  05                  DCR      B
$4d90:  85                  ADD      L
$4d91:  90                  SUB      B
$4d92:  85                  ADD      L
$4d93:  c0                  RNZ
$4d94:  05                  DCR      B
$4d95:  85                  ADD      L
$4d96:  40                  NOP
$4d97:  05                  DCR      B
$4d98:  01 04 03            LXI      B,$0304
$4d9b:  02                  STAX     B
$4d9c:  04                  INR      B
$4d9d:  86                  ADD      M
$4d9e:  04                  INR      B
$4d9f:  88                  ADC      B
$4da0:  03                  INX      B
$4da1:  89                  ADC      C
$4da2:  01 89 85            LXI      B,$8589
$4da5:  c1                  POP      B
$4da6:  89                  ADC      C
$4da7:  06 05               MVI      B,$05
$4da9:  03                  INX      B
$4daa:  05                  DCR      B
$4dab:  81                  ADD      C
$4dac:  04                  INR      B
$4dad:  83                  ADD      E
$4dae:  02                  STAX     B
$4daf:  84                  ADD      H
$4db0:  86                  ADD      M
$4db1:  84                  ADD      H
$4db2:  88                  ADC      B
$4db3:  83                  ADD      E
$4db4:  89                  ADC      C
$4db5:  81                  ADD      C
$4db6:  89                  ADC      C
$4db7:  03                  INX      B
$4db8:  c1                  POP      B
$4db9:  89                  ADC      C
$4dba:  09                  DAD      B
$4dbb:  89                  ADC      C
$4dbc:  86                  ADD      M
$4dbd:  05                  DCR      B
$4dbe:  86                  ADD      M
$4dbf:  05                  DCR      B
$4dc0:  03                  INX      B
$4dc1:  04                  INR      B
$4dc2:  05                  DCR      B
$4dc3:  02                  STAX     B
$4dc4:  06 89               MVI      B,$89
$4dc6:  06 c0               MVI      B,$c0
$4dc8:  05                  DCR      B
$4dc9:  00                  NOP
$4dca:  40                  NOP
$4dcb:  89                  ADC      C
$4dcc:  00                  NOP
$4dcd:  c1                  POP      B
$4dce:  89                  ADC      C
$4dcf:  07                  RLC
$4dd0:  05                  DCR      B
$4dd1:  85                  ADD      L
$4dd2:  86                  ADD      M
$4dd3:  85                  ADD      L
$4dd4:  88                  ADC      B
$4dd5:  84                  ADD      H
$4dd6:  89                  ADC      C
$4dd7:  82                  ADD      D
$4dd8:  89                  ADC      C
$4dd9:  04                  INR      B
$4dda:  c0                  RNZ
$4ddb:  05                  DCR      B
$4ddc:  04                  INR      B
$4ddd:  40                  NOP
$4dde:  8d                  ADC      L
$4ddf:  04                  INR      B
$4de0:  8f                  ADC      A
$4de1:  03                  INX      B
$4de2:  90                  SUB      B
$4de3:  01 90 85            LXI      B,$8590
$4de6:  c1                  POP      B
$4de7:  89                  ADC      C
$4de8:  09                  DAD      B
$4de9:  05                  DCR      B
$4dea:  86                  ADD      M
$4deb:  82                  ADD      D
$4dec:  82                  ADD      D
$4ded:  82                  ADD      D
$4dee:  02                  STAX     B
$4def:  89                  ADC      C
$4df0:  06 c0               MVI      B,$c0
$4df2:  05                  DCR      B
$4df3:  06 40               MVI      B,$40
$4df5:  82                  ADD      D
$4df6:  02                  STAX     B
$4df7:  c0                  RNZ
$4df8:  82                  ADD      D
$4df9:  82                  ADD      D
$4dfa:  40                  NOP
$4dfb:  89                  ADC      C
$4dfc:  86                  ADD      M
$4dfd:  c0                  RNZ
$4dfe:  05                  DCR      B
$4dff:  00                  NOP
$4e00:  40                  NOP
$4e01:  89                  ADC      C
$4e02:  00                  NOP
$4e03:  c1                  POP      B
$4e04:  89                  ADC      C
$4e05:  07                  RLC
$4e06:  03                  INX      B
$4e07:  85                  ADD      L
$4e08:  06 81               MVI      B,$81
$4e0a:  07                  RLC
$4e0b:  00                  NOP
$4e0c:  09                  DAD      B
$4e0d:  01 0a 01            LXI      B,$010a
$4e10:  0c                  INR      C
$4e11:  00                  NOP
$4e12:  0c                  INR      C
$4e13:  83                  ADD      E
$4e14:  0b                  DCX      B
$4e15:  85                  ADD      L
$4e16:  09                  DAD      B
$4e17:  85                  ADD      L
$4e18:  86                  ADD      M
$4e19:  85                  ADD      L
$4e1a:  88                  ADC      B
$4e1b:  84                  ADD      H
$4e1c:  89                  ADC      C
$4e1d:  82                  ADD      D
$4e1e:  89                  ADC      C
$4e1f:  01 88 03            LXI      B,$0388
$4e22:  86                  ADD      M
$4e23:  04                  INR      B
$4e24:  02                  STAX     B
$4e25:  04                  INR      B
$4e26:  04                  INR      B
$4e27:  03                  INX      B
$4e28:  05                  DCR      B
$4e29:  01 05 82            LXI      B,$8205
$4e2c:  c1                  POP      B
$4e2d:  89                  ADC      C
$4e2e:  07                  RLC
$4e2f:  05                  DCR      B
$4e30:  85                  ADD      L
$4e31:  89                  ADC      C
$4e32:  85                  ADD      L
$4e33:  c0                  RNZ
$4e34:  82                  ADD      D
$4e35:  85                  ADD      L
$4e36:  40                  NOP
$4e37:  82                  ADD      D
$4e38:  01 83 03            LXI      B,$0383
$4e3b:  84                  ADD      H
$4e3c:  04                  INR      B
$4e3d:  87                  ADD      A
$4e3e:  04                  INR      B
$4e3f:  88                  ADC      B
$4e40:  03                  INX      B
$4e41:  89                  ADC      C
$4e42:  01 89 85            LXI      B,$8589
$4e45:  c1                  POP      B
$4e46:  89                  ADC      C
$4e47:  08                  NOP
$4e48:  05                  DCR      B
$4e49:  85                  ADD      L
$4e4a:  89                  ADC      C
$4e4b:  85                  ADD      L
$4e4c:  89                  ADC      C
$4e4d:  00                  NOP
$4e4e:  88                  ADC      B
$4e4f:  02                  STAX     B
$4e50:  87                  ADD      A
$4e51:  03                  INX      B
$4e52:  84                  ADD      H
$4e53:  03                  INX      B
$4e54:  83                  ADD      E
$4e55:  02                  STAX     B
$4e56:  82                  ADD      D
$4e57:  00                  NOP
$4e58:  82                  ADD      D
$4e59:  85                  ADD      L
$4e5a:  c0                  RNZ
$4e5b:  05                  DCR      B
$4e5c:  05                  DCR      B
$4e5d:  40                  NOP
$4e5e:  89                  ADC      C
$4e5f:  05                  DCR      B
$4e60:  c1                  POP      B
$4e61:  89                  ADC      C
$4e62:  06 04               MVI      B,$04
$4e64:  84                  ADD      H
$4e65:  05                  DCR      B
$4e66:  82                  ADD      D
$4e67:  05                  DCR      B
$4e68:  00                  NOP
$4e69:  04                  INR      B
$4e6a:  02                  STAX     B
$4e6b:  03                  INX      B
$4e6c:  03                  INX      B
$4e6d:  00                  NOP
$4e6e:  03                  INX      B
$4e6f:  81                  ADD      C
$4e70:  02                  STAX     B
$4e71:  82                  ADD      D
$4e72:  00                  NOP
$4e73:  83                  ADD      E
$4e74:  02                  STAX     B
$4e75:  84                  ADD      H
$4e76:  03                  INX      B
$4e77:  87                  ADD      A
$4e78:  03                  INX      B
$4e79:  88                  ADC      B
$4e7a:  02                  STAX     B
$4e7b:  89                  ADC      C
$4e7c:  00                  NOP
$4e7d:  89                  ADC      C
$4e7e:  82                  ADD      D
$4e7f:  88                  ADC      B
$4e80:  84                  ADD      H
$4e81:  c0                  RNZ
$4e82:  82                  ADD      D
$4e83:  82                  ADD      D
$4e84:  40                  NOP
$4e85:  82                  ADD      D
$4e86:  00                  NOP
$4e87:  c1                  POP      B
$4e88:  89                  ADC      C
$4e89:  09                  DAD      B
$4e8a:  05                  DCR      B
$4e8b:  86                  ADD      M
$4e8c:  86                  ADD      M
$4e8d:  86                  ADD      M
$4e8e:  88                  ADC      B
$4e8f:  85                  ADD      L
$4e90:  89                  ADC      C
$4e91:  83                  ADD      E
$4e92:  89                  ADC      C
$4e93:  06 05               MVI      B,$05
$4e95:  06 c0               MVI      B,$c0
$4e97:  05                  DCR      B
$4e98:  00                  NOP
$4e99:  40                  NOP
$4e9a:  89                  ADC      C
$4e9b:  00                  NOP
$4e9c:  c1                  POP      B
$4e9d:  89                  ADC      C
$4e9e:  07                  RLC
$4e9f:  05                  DCR      B
$4ea0:  85                  ADD      L
$4ea1:  05                  DCR      B
$4ea2:  01 04 03            LXI      B,$0304
$4ea5:  02                  STAX     B
$4ea6:  04                  INR      B
$4ea7:  86                  ADD      M
$4ea8:  04                  INR      B
$4ea9:  88                  ADC      B
$4eaa:  03                  INX      B
$4eab:  89                  ADC      C
$4eac:  01 89 85            LXI      B,$8589
$4eaf:  c0                  RNZ
$4eb0:  82                  ADD      D
$4eb1:  82                  ADD      D
$4eb2:  40                  NOP
$4eb3:  82                  ADD      D
$4eb4:  04                  INR      B
$4eb5:  c1                  POP      B
$4eb6:  89                  ADC      C
$4eb7:  0a                  LDAX     B
$4eb8:  05                  DCR      B
$4eb9:  87                  ADD      A
$4eba:  86                  ADD      M
$4ebb:  87                  ADD      A
$4ebc:  88                  ADC      B
$4ebd:  86                  ADD      M
$4ebe:  89                  ADC      C
$4ebf:  84                  ADD      H
$4ec0:  89                  ADC      C
$4ec1:  07                  RLC
$4ec2:  8c                  ADC      H
$4ec3:  07                  RLC
$4ec4:  c0                  RNZ
$4ec5:  05                  DCR      B
$4ec6:  81                  ADD      C
$4ec7:  40                  NOP
$4ec8:  89                  ADC      C
$4ec9:  81                  ADD      C
$4eca:  c0                  RNZ
$4ecb:  05                  DCR      B
$4ecc:  05                  DCR      B
$4ecd:  40                  NOP
$4ece:  89                  ADC      C
$4ecf:  05                  DCR      B
$4ed0:  c1                  POP      B
$4ed1:  89                  ADC      C
$4ed2:  07                  RLC
$4ed3:  05                  DCR      B
$4ed4:  85                  ADD      L
$4ed5:  00                  NOP
$4ed6:  85                  ADD      L
$4ed7:  82                  ADD      D
$4ed8:  84                  ADD      H
$4ed9:  83                  ADD      E
$4eda:  82                  ADD      D
$4edb:  83                  ADD      E
$4edc:  04                  INR      B
$4edd:  c0                  RNZ
$4ede:  05                  DCR      B
$4edf:  04                  INR      B
$4ee0:  40                  NOP
$4ee1:  89                  ADC      C
$4ee2:  04                  INR      B
$4ee3:  c1                  POP      B
$4ee4:  89                  ADC      C
$4ee5:  08                  NOP
$4ee6:  05                  DCR      B
$4ee7:  86                  ADD      M
$4ee8:  05                  DCR      B
$4ee9:  84                  ADD      H
$4eea:  89                  ADC      C
$4eeb:  84                  ADD      H
$4eec:  89                  ADC      C
$4eed:  02                  STAX     B
$4eee:  88                  ADC      B
$4eef:  04                  INR      B
$4ef0:  87                  ADD      A
$4ef1:  05                  DCR      B
$4ef2:  84                  ADD      H
$4ef3:  05                  DCR      B
$4ef4:  83                  ADD      E
$4ef5:  04                  INR      B
$4ef6:  82                  ADD      D
$4ef7:  02                  STAX     B
$4ef8:  82                  ADD      D
$4ef9:  84                  ADD      H
$4efa:  c1                  POP      B
$4efb:  89                  ADC      C
$4efc:  09                  DAD      B
$4efd:  0c                  INR      C
$4efe:  86                  ADD      M
$4eff:  89                  ADC      C
$4f00:  86                  ADD      M
$4f01:  c0                  RNZ
$4f02:  00                  NOP
$4f03:  86                  ADD      M
$4f04:  40                  NOP
$4f05:  00                  NOP
$4f06:  82                  ADD      D
$4f07:  86                  ADD      M
$4f08:  82                  ADD      D
$4f09:  88                  ADC      B
$4f0a:  81                  ADD      C
$4f0b:  89                  ADC      C
$4f0c:  00                  NOP
$4f0d:  89                  ADC      C
$4f0e:  04                  INR      B
$4f0f:  88                  ADC      B
$4f10:  05                  DCR      B
$4f11:  86                  ADD      M
$4f12:  06 09               MVI      B,$09
$4f14:  06 0b               MVI      B,$0b
$4f16:  05                  DCR      B
$4f17:  0c                  INR      C
$4f18:  04                  INR      B
$4f19:  0c                  INR      C
$4f1a:  00                  NOP
$4f1b:  0b                  DCX      B
$4f1c:  81                  ADD      C
$4f1d:  09                  DAD      B
$4f1e:  82                  ADD      D
$4f1f:  00                  NOP
$4f20:  82                  ADD      D
$4f21:  c1                  POP      B
$4f22:  89                  ADC      C
$4f23:  09                  DAD      B
$4f24:  0c                  INR      C
$4f25:  00                  NOP
$4f26:  89                  ADC      C
$4f27:  86                  ADD      M
$4f28:  c0                  RNZ
$4f29:  0c                  INR      C
$4f2a:  00                  NOP
$4f2b:  40                  NOP
$4f2c:  89                  ADC      C
$4f2d:  06 c0               MVI      B,$c0
$4f2f:  82                  ADD      D
$4f30:  84                  ADD      H
$4f31:  40                  NOP
$4f32:  82                  ADD      D
$4f33:  04                  INR      B
$4f34:  c1                  POP      B
$4f35:  89                  ADC      C
$4f36:  08                  NOP
$4f37:  89                  ADC      C
$4f38:  86                  ADD      M
$4f39:  0c                  INR      C
$4f3a:  86                  ADD      M
$4f3b:  0c                  INR      C
$4f3c:  04                  INR      B
$4f3d:  c0                  RNZ
$4f3e:  02                  STAX     B
$4f3f:  86                  ADD      M
$4f40:  40                  NOP
$4f41:  02                  STAX     B
$4f42:  02                  STAX     B
$4f43:  01 04 81            LXI      B,$8104
$4f46:  05                  DCR      B
$4f47:  86                  ADD      M
$4f48:  05                  DCR      B
$4f49:  88                  ADC      B
$4f4a:  04                  INR      B
$4f4b:  89                  ADC      C
$4f4c:  02                  STAX     B
$4f4d:  89                  ADC      C
$4f4e:  86                  ADD      M
$4f4f:  c1                  POP      B
$4f50:  89                  ADC      C
$4f51:  09                  DAD      B
$4f52:  0c                  INR      C
$4f53:  86                  ADD      M
$4f54:  89                  ADC      C
$4f55:  86                  ADD      M
$4f56:  89                  ADC      C
$4f57:  06 8c               MVI      B,$8c
$4f59:  06 c0               MVI      B,$c0
$4f5b:  0c                  INR      C
$4f5c:  04                  INR      B
$4f5d:  40                  NOP
$4f5e:  89                  ADC      C
$4f5f:  04                  INR      B
$4f60:  c1                  POP      B
$4f61:  89                  ADC      C
$4f62:  09                  DAD      B
$4f63:  8c                  ADC      H
$4f64:  86                  ADD      M
$4f65:  89                  ADC      C
$4f66:  86                  ADD      M
$4f67:  89                  ADC      C
$4f68:  06 8c               MVI      B,$8c
$4f6a:  06 c0               MVI      B,$c0
$4f6c:  89                  ADC      C
$4f6d:  84                  ADD      H
$4f6e:  40                  NOP
$4f6f:  0c                  INR      C
$4f70:  81                  ADD      C
$4f71:  0c                  INR      C
$4f72:  04                  INR      B
$4f73:  89                  ADC      C
$4f74:  04                  INR      B
$4f75:  c1                  POP      B
$4f76:  89                  ADC      C
$4f77:  07                  RLC
$4f78:  0c                  INR      C
$4f79:  04                  INR      B
$4f7a:  0c                  INR      C
$4f7b:  85                  ADD      L
$4f7c:  89                  ADC      C
$4f7d:  85                  ADD      L
$4f7e:  89                  ADC      C
$4f7f:  04                  INR      B
$4f80:  c0                  RNZ
$4f81:  02                  STAX     B
$4f82:  85                  ADD      L
$4f83:  40                  NOP
$4f84:  02                  STAX     B
$4f85:  01 c1 89            LXI      B,$89c1
$4f88:  0b                  DCX      B
$4f89:  0c                  INR      C
$4f8a:  00                  NOP
$4f8b:  89                  ADC      C
$4f8c:  00                  NOP
$4f8d:  c0                  RNZ
$4f8e:  09                  DAD      B
$4f8f:  85                  ADD      L
$4f90:  40                  NOP
$4f91:  08                  NOP
$4f92:  87                  ADD      A
$4f93:  06 88               MVI      B,$88
$4f95:  81                  ADD      C
$4f96:  88                  ADC      B
$4f97:  83                  ADD      E
$4f98:  87                  ADD      A
$4f99:  84                  ADD      H
$4f9a:  85                  ADD      L
$4f9b:  84                  ADD      H
$4f9c:  05                  DCR      B
$4f9d:  83                  ADD      E
$4f9e:  07                  RLC
$4f9f:  81                  ADD      C
$4fa0:  08                  NOP
$4fa1:  06 08               MVI      B,$08
$4fa3:  08                  NOP
$4fa4:  07                  RLC
$4fa5:  09                  DAD      B
$4fa6:  05                  DCR      B
$4fa7:  09                  DAD      B
$4fa8:  85                  ADD      L
$4fa9:  c1                  POP      B
$4faa:  89                  ADC      C
$4fab:  07                  RLC
$4fac:  89                  ADC      C
$4fad:  85                  ADD      L
$4fae:  0c                  INR      C
$4faf:  85                  ADD      L
$4fb0:  0c                  INR      C
$4fb1:  04                  INR      B
$4fb2:  c1                  POP      B
$4fb3:  89                  ADC      C
$4fb4:  09                  DAD      B
$4fb5:  0c                  INR      C
$4fb6:  86                  ADD      M
$4fb7:  89                  ADC      C
$4fb8:  06 c0               MVI      B,$c0
$4fba:  0c                  INR      C
$4fbb:  06 40               MVI      B,$40
$4fbd:  89                  ADC      C
$4fbe:  86                  ADD      M
$4fbf:  c1                  POP      B
$4fc0:  89                  ADC      C
$4fc1:  08                  NOP
$4fc2:  0c                  INR      C
$4fc3:  86                  ADD      M
$4fc4:  89                  ADC      C
$4fc5:  86                  ADD      M
$4fc6:  0c                  INR      C
$4fc7:  05                  DCR      B
$4fc8:  89                  ADC      C
$4fc9:  05                  DCR      B
$4fca:  c1                  POP      B
$4fcb:  89                  ADC      C
$4fcc:  08                  NOP
$4fcd:  0c                  INR      C
$4fce:  86                  ADD      M
$4fcf:  89                  ADC      C
$4fd0:  86                  ADD      M
$4fd1:  0c                  INR      C
$4fd2:  05                  DCR      B
$4fd3:  89                  ADC      C
$4fd4:  05                  DCR      B
$4fd5:  c0                  RNZ
$4fd6:  0e 83               MVI      C,$83
$4fd8:  40                  NOP
$4fd9:  0e 02               MVI      C,$02
$4fdb:  c1                  POP      B
$4fdc:  89                  ADC      C
$4fdd:  08                  NOP
$4fde:  0c                  INR      C
$4fdf:  86                  ADD      M
$4fe0:  89                  ADC      C
$4fe1:  86                  ADD      M
$4fe2:  c0                  RNZ
$4fe3:  0c                  INR      C
$4fe4:  05                  DCR      B
$4fe5:  40                  NOP
$4fe6:  82                  ADD      D
$4fe7:  86                  ADD      M
$4fe8:  c0                  RNZ
$4fe9:  02                  STAX     B
$4fea:  83                  ADD      E
$4feb:  40                  NOP
$4fec:  89                  ADC      C
$4fed:  05                  DCR      B
$4fee:  c1                  POP      B
$4fef:  89                  ADC      C
$4ff0:  08                  NOP
$4ff1:  89                  ADC      C
$4ff2:  86                  ADD      M
$4ff3:  0c                  INR      C
$4ff4:  00                  NOP
$4ff5:  0c                  INR      C
$4ff6:  05                  DCR      B
$4ff7:  89                  ADC      C
$4ff8:  05                  DCR      B
$4ff9:  c1                  POP      B
$4ffa:  89                  ADC      C
$4ffb:  0a                  LDAX     B
$4ffc:  89                  ADC      C
$4ffd:  87                  ADD      A
$4ffe:  0c                  INR      C
$4fff:  87                  ADD      A
$5000:  00                  NOP
$5001:  00                  NOP
$5002:  0c                  INR      C
$5003:  07                  RLC
$5004:  89                  ADC      C
$5005:  07                  RLC
$5006:  c1                  POP      B
$5007:  89                  ADC      C
$5008:  08                  NOP
$5009:  0c                  INR      C
$500a:  86                  ADD      M
$500b:  89                  ADC      C
$500c:  86                  ADD      M
$500d:  c0                  RNZ
$500e:  0c                  INR      C
$500f:  05                  DCR      B
$5010:  40                  NOP
$5011:  89                  ADC      C
$5012:  05                  DCR      B
$5013:  c0                  RNZ
$5014:  01 86 40            LXI      B,$4086
$5017:  01 05 c1            LXI      B,$c105
$501a:  89                  ADC      C
$501b:  08                  NOP
$501c:  0c                  INR      C
$501d:  83                  ADD      E
$501e:  0b                  DCX      B
$501f:  85                  ADD      L
$5020:  09                  DAD      B
$5021:  86                  ADD      M
$5022:  86                  ADD      M
$5023:  86                  ADD      M
$5024:  88                  ADC      B
$5025:  85                  ADD      L
$5026:  89                  ADC      C
$5027:  83                  ADD      E
$5028:  89                  ADC      C
$5029:  02                  STAX     B
$502a:  88                  ADC      B
$502b:  04                  INR      B
$502c:  86                  ADD      M
$502d:  05                  DCR      B
$502e:  09                  DAD      B
$502f:  05                  DCR      B
$5030:  0b                  DCX      B
$5031:  04                  INR      B
$5032:  0c                  INR      C
$5033:  02                  STAX     B
$5034:  0c                  INR      C
$5035:  83                  ADD      E
$5036:  c1                  POP      B
$5037:  89                  ADC      C
$5038:  08                  NOP
$5039:  89                  ADC      C
$503a:  86                  ADD      M
$503b:  0c                  INR      C
$503c:  86                  ADD      M
$503d:  0c                  INR      C
$503e:  05                  DCR      B
$503f:  89                  ADC      C
$5040:  05                  DCR      B
$5041:  c1                  POP      B
$5042:  89                  ADC      C
$5043:  08                  NOP
$5044:  0c                  INR      C
$5045:  05                  DCR      B
$5046:  89                  ADC      C
$5047:  05                  DCR      B
$5048:  c0                  RNZ
$5049:  0c                  INR      C
$504a:  05                  DCR      B
$504b:  40                  NOP
$504c:  0c                  INR      C
$504d:  83                  ADD      E
$504e:  0b                  DCX      B
$504f:  85                  ADD      L
$5050:  09                  DAD      B
$5051:  86                  ADD      M
$5052:  03                  INX      B
$5053:  86                  ADD      M
$5054:  01 85 00            LXI      B,$0085
$5057:  83                  ADD      E
$5058:  00                  NOP
$5059:  05                  DCR      B
$505a:  c0                  RNZ
$505b:  00                  NOP
$505c:  82                  ADD      D
$505d:  40                  NOP
$505e:  89                  ADC      C
$505f:  86                  ADD      M
$5060:  c1                  POP      B
$5061:  89                  ADC      C
$5062:  08                  NOP
$5063:  89                  ADC      C
$5064:  86                  ADD      M
$5065:  0c                  INR      C
$5066:  86                  ADD      M
$5067:  0c                  INR      C
$5068:  02                  STAX     B
$5069:  0b                  DCX      B
$506a:  04                  INR      B
$506b:  09                  DAD      B
$506c:  05                  DCR      B
$506d:  03                  INX      B
$506e:  05                  DCR      B
$506f:  01 04 00            LXI      B,$0004
$5072:  02                  STAX     B
$5073:  00                  NOP
$5074:  86                  ADD      M
$5075:  c1                  POP      B
$5076:  89                  ADC      C
$5077:  07                  RLC
$5078:  0c                  INR      C
$5079:  04                  INR      B
$507a:  0c                  INR      C
$507b:  82                  ADD      D
$507c:  0b                  DCX      B
$507d:  84                  ADD      H
$507e:  09                  DAD      B
$507f:  85                  ADD      L
$5080:  86                  ADD      M
$5081:  85                  ADD      L
$5082:  88                  ADC      B
$5083:  84                  ADD      H
$5084:  89                  ADC      C
$5085:  82                  ADD      D
$5086:  89                  ADC      C
$5087:  04                  INR      B
$5088:  c1                  POP      B
$5089:  89                  ADC      C
$508a:  09                  DAD      B
$508b:  0c                  INR      C
$508c:  00                  NOP
$508d:  89                  ADC      C
$508e:  00                  NOP
$508f:  c0                  RNZ
$5090:  0c                  INR      C
$5091:  86                  ADD      M
$5092:  40                  NOP
$5093:  0c                  INR      C
$5094:  06 c1               MVI      B,$c1
$5096:  89                  ADC      C
$5097:  08                  NOP
$5098:  0c                  INR      C
$5099:  05                  DCR      B
$509a:  86                  ADD      M
$509b:  05                  DCR      B
$509c:  88                  ADC      B
$509d:  04                  INR      B
$509e:  89                  ADC      C
$509f:  02                  STAX     B
$50a0:  89                  ADC      C
$50a1:  84                  ADD      H
$50a2:  c0                  RNZ
$50a3:  0c                  INR      C
$50a4:  86                  ADD      M
$50a5:  40                  NOP
$50a6:  03                  INX      B
$50a7:  86                  ADD      M
$50a8:  01 85 00            LXI      B,$0085
$50ab:  83                  ADD      E
$50ac:  00                  NOP
$50ad:  05                  DCR      B
$50ae:  c1                  POP      B
$50af:  89                  ADC      C
$50b0:  0a                  LDAX     B
$50b1:  0c                  INR      C
$50b2:  87                  ADD      A
$50b3:  02                  STAX     B
$50b4:  82                  ADD      D
$50b5:  02                  STAX     B
$50b6:  02                  STAX     B
$50b7:  89                  ADC      C
$50b8:  07                  RLC
$50b9:  c0                  RNZ
$50ba:  0c                  INR      C
$50bb:  07                  RLC
$50bc:  40                  NOP
$50bd:  02                  STAX     B
$50be:  02                  STAX     B
$50bf:  c0                  RNZ
$50c0:  02                  STAX     B
$50c1:  82                  ADD      D
$50c2:  40                  NOP
$50c3:  89                  ADC      C
$50c4:  87                  ADD      A
$50c5:  c0                  RNZ
$50c6:  0c                  INR      C
$50c7:  00                  NOP
$50c8:  40                  NOP
$50c9:  89                  ADC      C
$50ca:  00                  NOP
$50cb:  c1                  POP      B
$50cc:  89                  ADC      C
$50cd:  08                  NOP
$50ce:  0c                  INR      C
$50cf:  86                  ADD      M
$50d0:  89                  ADC      C
$50d1:  86                  ADD      M
$50d2:  89                  ADC      C
$50d3:  01 88 03            LXI      B,$0388
$50d6:  86                  ADD      M
$50d7:  05                  DCR      B
$50d8:  81                  ADD      C
$50d9:  05                  DCR      B
$50da:  01 03 02            LXI      B,$0203
$50dd:  01 03 03            LXI      B,$0303
$50e0:  05                  DCR      B
$50e1:  04                  INR      B
$50e2:  09                  DAD      B
$50e3:  04                  INR      B
$50e4:  0b                  DCX      B
$50e5:  03                  INX      B
$50e6:  0c                  INR      C
$50e7:  01 0c 86            LXI      B,$860c
$50ea:  c0                  RNZ
$50eb:  02                  STAX     B
$50ec:  86                  ADD      M
$50ed:  40                  NOP
$50ee:  02                  STAX     B
$50ef:  01 c1 89            LXI      B,$89c1
$50f2:  08                  NOP
$50f3:  0c                  INR      C
$50f4:  86                  ADD      M
$50f5:  89                  ADC      C
$50f6:  86                  ADD      M
$50f7:  c0                  RNZ
$50f8:  02                  STAX     B
$50f9:  86                  ADD      M
$50fa:  40                  NOP
$50fb:  02                  STAX     B
$50fc:  02                  STAX     B
$50fd:  01 04 81            LXI      B,$8104
$5100:  05                  DCR      B
$5101:  86                  ADD      M
$5102:  05                  DCR      B
$5103:  88                  ADC      B
$5104:  04                  INR      B
$5105:  89                  ADC      C
$5106:  02                  STAX     B
$5107:  89                  ADC      C
$5108:  86                  ADD      M
$5109:  c1                  POP      B
$510a:  89                  ADC      C
$510b:  09                  DAD      B
$510c:  0c                  INR      C
$510d:  86                  ADD      M
$510e:  89                  ADC      C
$510f:  86                  ADD      M
$5110:  c0                  RNZ
$5111:  02                  STAX     B
$5112:  86                  ADD      M
$5113:  40                  NOP
$5114:  02                  STAX     B
$5115:  00                  NOP
$5116:  01 02 81            LXI      B,$8102
$5119:  03                  INX      B
$511a:  86                  ADD      M
$511b:  03                  INX      B
$511c:  88                  ADC      B
$511d:  02                  STAX     B
$511e:  89                  ADC      C
$511f:  00                  NOP
$5120:  89                  ADC      C
$5121:  86                  ADD      M
$5122:  c0                  RNZ
$5123:  0c                  INR      C
$5124:  06 40               MVI      B,$40
$5126:  89                  ADC      C
$5127:  06 c1               MVI      B,$c1
$5129:  89                  ADC      C
$512a:  08                  NOP
$512b:  0a                  LDAX     B
$512c:  85                  ADD      L
$512d:  0b                  DCX      B
$512e:  84                  ADD      H
$512f:  0c                  INR      C
$5130:  82                  ADD      D
$5131:  0c                  INR      C
$5132:  02                  STAX     B
$5133:  0b                  DCX      B
$5134:  04                  INR      B
$5135:  09                  DAD      B
$5136:  05                  DCR      B
$5137:  05                  DCR      B
$5138:  05                  DCR      B
$5139:  03                  INX      B
$513a:  04                  INR      B
$513b:  02                  STAX     B
$513c:  01 01 04            LXI      B,$0401
$513f:  81                  ADD      C
$5140:  05                  DCR      B
$5141:  86                  ADD      M
$5142:  05                  DCR      B
$5143:  88                  ADC      B
$5144:  04                  INR      B
$5145:  89                  ADC      C
$5146:  02                  STAX     B
$5147:  89                  ADC      C
$5148:  83                  ADD      E
$5149:  88                  ADC      B
$514a:  85                  ADD      L
$514b:  87                  ADD      A
$514c:  86                  ADD      M
$514d:  c0                  RNZ
$514e:  02                  STAX     B
$514f:  82                  ADD      D
$5150:  40                  NOP
$5151:  02                  STAX     B
$5152:  01 c1 89            LXI      B,$89c1
$5155:  0a                  LDAX     B
$5156:  0c                  INR      C
$5157:  87                  ADD      A
$5158:  89                  ADC      C
$5159:  87                  ADD      A
$515a:  89                  ADC      C
$515b:  07                  RLC
$515c:  0c                  INR      C
$515d:  07                  RLC
$515e:  c0                  RNZ
$515f:  0c                  INR      C
$5160:  00                  NOP
$5161:  40                  NOP
$5162:  89                  ADC      C
$5163:  00                  NOP
$5164:  c1                  POP      B
$5165:  89                  ADC      C
$5166:  08                  NOP
$5167:  0c                  INR      C
$5168:  86                  ADD      M
$5169:  0c                  INR      C
$516a:  02                  STAX     B
$516b:  0b                  DCX      B
$516c:  04                  INR      B
$516d:  09                  DAD      B
$516e:  05                  DCR      B
$516f:  86                  ADD      M
$5170:  05                  DCR      B
$5171:  88                  ADC      B
$5172:  04                  INR      B
$5173:  89                  ADC      C
$5174:  02                  STAX     B
$5175:  89                  ADC      C
$5176:  86                  ADD      M
$5177:  c0                  RNZ
$5178:  02                  STAX     B
$5179:  82                  ADD      D
$517a:  40                  NOP
$517b:  02                  STAX     B
$517c:  05                  DCR      B
$517d:  c1                  POP      B
$517e:  89                  ADC      C
$517f:  0b                  DCX      B
$5180:  0c                  INR      C
$5181:  88                  ADC      B
$5182:  89                  ADC      C
$5183:  88                  ADC      B
$5184:  89                  ADC      C
$5185:  08                  NOP
$5186:  8c                  ADC      H
$5187:  08                  NOP
$5188:  c0                  RNZ
$5189:  0c                  INR      C
$518a:  81                  ADD      C
$518b:  40                  NOP
$518c:  89                  ADC      C
$518d:  81                  ADD      C
$518e:  c0                  RNZ
$518f:  0c                  INR      C
$5190:  06 40               MVI      B,$40
$5192:  89                  ADC      C
$5193:  06 c1               MVI      B,$c1
$5195:  89                  ADC      C
$5196:  08                  NOP
$5197:  0c                  INR      C
$5198:  86                  ADD      M
$5199:  03                  INX      B
$519a:  86                  ADD      M
$519b:  01 85 00            LXI      B,$0085
$519e:  82                  ADD      D
$519f:  00                  NOP
$51a0:  05                  DCR      B
$51a1:  c0                  RNZ
$51a2:  0c                  INR      C
$51a3:  05                  DCR      B
$51a4:  40                  NOP
$51a5:  89                  ADC      C
$51a6:  05                  DCR      B
$51a7:  c1                  POP      B
$51a8:  89                  ADC      C
$51a9:  0a                  LDAX     B
$51aa:  02                  STAX     B
$51ab:  03                  INX      B
$51ac:  03                  INX      B
$51ad:  01 03 81            LXI      B,$8103
$51b0:  01 82 00            LXI      B,$0082
$51b3:  82                  ADD      D
$51b4:  82                  ADD      D
$51b5:  81                  ADD      C
$51b6:  82                  ADD      D
$51b7:  01 81 03            LXI      B,$0381
$51ba:  c0                  RNZ
$51bb:  03                  INX      B
$51bc:  03                  INX      B
$51bd:  40                  NOP
$51be:  81                  ADD      C
$51bf:  03                  INX      B
$51c0:  82                  ADD      D
$51c1:  04                  INR      B
$51c2:  82                  ADD      D
$51c3:  06 00               MVI      B,$00
$51c5:  07                  RLC
$51c6:  01 07 04            LXI      B,$0407
$51c9:  06 06               MVI      B,$06
$51cb:  04                  INR      B
$51cc:  07                  RLC
$51cd:  00                  NOP
$51ce:  06 83               MVI      B,$83
$51d0:  04                  INR      B
$51d1:  85                  ADD      L
$51d2:  01 86 00            LXI      B,$0086
$51d5:  86                  ADD      M
$51d6:  83                  ADD      E
$51d7:  85                  ADD      L
$51d8:  85                  ADD      L
$51d9:  83                  ADD      E
$51da:  86                  ADD      M
$51db:  00                  NOP
$51dc:  86                  ADD      M
$51dd:  01 85 04            LXI      B,$0485
$51e0:  c1                  POP      B
$51e1:  89                  ADC      C
$51e2:  08                  NOP
$51e3:  0c                  INR      C
$51e4:  86                  ADD      M
$51e5:  89                  ADC      C
$51e6:  86                  ADD      M
$51e7:  89                  ADC      C
$51e8:  01 88 03            LXI      B,$0388
$51eb:  86                  ADD      M
$51ec:  05                  DCR      B
$51ed:  81                  ADD      C
$51ee:  05                  DCR      B
$51ef:  01 03 02            LXI      B,$0203
$51f2:  01 03 03            LXI      B,$0303
$51f5:  05                  DCR      B
$51f6:  04                  INR      B
$51f7:  09                  DAD      B
$51f8:  04                  INR      B
$51f9:  0b                  DCX      B
$51fa:  03                  INX      B
$51fb:  0c                  INR      C
$51fc:  01 0c 86            LXI      B,$860c
$51ff:  c0                  RNZ
$5200:  02                  STAX     B
$5201:  86                  ADD      M
$5202:  40                  NOP
$5203:  02                  STAX     B
$5204:  01 c1 89            LXI      B,$89c1
$5207:  07                  RLC
$5208:  0c                  INR      C
$5209:  04                  INR      B
$520a:  0c                  INR      C
$520b:  82                  ADD      D
$520c:  0b                  DCX      B
$520d:  84                  ADD      H
$520e:  09                  DAD      B
$520f:  85                  ADD      L
$5210:  86                  ADD      M
$5211:  85                  ADD      L
$5212:  88                  ADC      B
$5213:  84                  ADD      H
$5214:  89                  ADC      C
$5215:  82                  ADD      D
$5216:  89                  ADC      C
$5217:  04                  INR      B
$5218:  c1                  POP      B
$5219:  89                  ADC      C
$521a:  08                  NOP
$521b:  0c                  INR      C
$521c:  85                  ADD      L
$521d:  89                  ADC      C
$521e:  85                  ADD      L
$521f:  89                  ADC      C
$5220:  02                  STAX     B
$5221:  88                  ADC      B
$5222:  04                  INR      B
$5223:  86                  ADD      M
$5224:  05                  DCR      B
$5225:  09                  DAD      B
$5226:  05                  DCR      B
$5227:  0b                  DCX      B
$5228:  04                  INR      B
$5229:  0c                  INR      C
$522a:  02                  STAX     B
$522b:  0c                  INR      C
$522c:  85                  ADD      L
$522d:  c1                  POP      B
$522e:  89                  ADC      C
$522f:  07                  RLC
$5230:  0c                  INR      C
$5231:  04                  INR      B
$5232:  0c                  INR      C
$5233:  85                  ADD      L
$5234:  89                  ADC      C
$5235:  85                  ADD      L
$5236:  89                  ADC      C
$5237:  04                  INR      B
$5238:  c0                  RNZ
$5239:  02                  STAX     B
$523a:  85                  ADD      L
$523b:  40                  NOP
$523c:  02                  STAX     B
$523d:  01 c1 89            LXI      B,$89c1
$5240:  07                  RLC
$5241:  0c                  INR      C
$5242:  04                  INR      B
$5243:  0c                  INR      C
$5244:  85                  ADD      L
$5245:  89                  ADC      C
$5246:  85                  ADD      L
$5247:  c0                  RNZ
$5248:  02                  STAX     B
$5249:  85                  ADD      L
$524a:  40                  NOP
$524b:  02                  STAX     B
$524c:  04                  INR      B
$524d:  c1                  POP      B
$524e:  89                  ADC      C
$524f:  08                  NOP
$5250:  0c                  INR      C
$5251:  05                  DCR      B
$5252:  0c                  INR      C
$5253:  82                  ADD      D
$5254:  0b                  DCX      B
$5255:  84                  ADD      H
$5256:  09                  DAD      B
$5257:  85                  ADD      L
$5258:  86                  ADD      M
$5259:  85                  ADD      L
$525a:  88                  ADC      B
$525b:  84                  ADD      H
$525c:  89                  ADC      C
$525d:  82                  ADD      D
$525e:  89                  ADC      C
$525f:  05                  DCR      B
$5260:  02                  STAX     B
$5261:  05                  DCR      B
$5262:  02                  STAX     B
$5263:  02                  STAX     B
$5264:  c1                  POP      B
$5265:  89                  ADC      C
$5266:  08                  NOP
$5267:  0c                  INR      C
$5268:  86                  ADD      M
$5269:  89                  ADC      C
$526a:  86                  ADD      M
$526b:  c0                  RNZ
$526c:  0c                  INR      C
$526d:  05                  DCR      B
$526e:  40                  NOP
$526f:  89                  ADC      C
$5270:  05                  DCR      B
$5271:  c0                  RNZ
$5272:  01 86 40            LXI      B,$4086
$5275:  01 05 c1            LXI      B,$c105
$5278:  89                  ADC      C
$5279:  03                  INX      B
$527a:  0c                  INR      C
$527b:  00                  NOP
$527c:  89                  ADC      C
$527d:  00                  NOP
$527e:  c1                  POP      B
$527f:  89                  ADC      C
$5280:  06 0c               MVI      B,$0c
$5282:  03                  INX      B
$5283:  86                  ADD      M
$5284:  03                  INX      B
$5285:  88                  ADC      B
$5286:  02                  STAX     B
$5287:  89                  ADC      C
$5288:  00                  NOP
$5289:  89                  ADC      C
$528a:  83                  ADD      E
$528b:  c1                  POP      B
$528c:  89                  ADC      C
$528d:  08                  NOP
$528e:  0c                  INR      C
$528f:  86                  ADD      M
$5290:  89                  ADC      C
$5291:  86                  ADD      M
$5292:  c0                  RNZ
$5293:  0c                  INR      C
$5294:  05                  DCR      B
$5295:  40                  NOP
$5296:  82                  ADD      D
$5297:  86                  ADD      M
$5298:  c0                  RNZ
$5299:  02                  STAX     B
$529a:  83                  ADD      E
$529b:  40                  NOP
$529c:  89                  ADC      C
$529d:  05                  DCR      B
$529e:  c1                  POP      B
$529f:  89                  ADC      C
$52a0:  06 0c               MVI      B,$0c
$52a2:  83                  ADD      E
$52a3:  89                  ADC      C
$52a4:  83                  ADD      E
$52a5:  89                  ADC      C
$52a6:  03                  INX      B
$52a7:  c1                  POP      B
$52a8:  89                  ADC      C
$52a9:  0a                  LDAX     B
$52aa:  89                  ADC      C
$52ab:  87                  ADD      A
$52ac:  0c                  INR      C
$52ad:  87                  ADD      A
$52ae:  00                  NOP
$52af:  00                  NOP
$52b0:  0c                  INR      C
$52b1:  07                  RLC
$52b2:  89                  ADC      C
$52b3:  07                  RLC
$52b4:  c1                  POP      B
$52b5:  89                  ADC      C
$52b6:  08                  NOP
$52b7:  89                  ADC      C
$52b8:  85                  ADD      L
$52b9:  0c                  INR      C
$52ba:  85                  ADD      L
$52bb:  89                  ADC      C
$52bc:  05                  DCR      B
$52bd:  0c                  INR      C
$52be:  05                  DCR      B
$52bf:  c1                  POP      B
$52c0:  89                  ADC      C
$52c1:  08                  NOP
$52c2:  0c                  INR      C
$52c3:  83                  ADD      E
$52c4:  0b                  DCX      B
$52c5:  85                  ADD      L
$52c6:  09                  DAD      B
$52c7:  86                  ADD      M
$52c8:  86                  ADD      M
$52c9:  86                  ADD      M
$52ca:  88                  ADC      B
$52cb:  85                  ADD      L
$52cc:  89                  ADC      C
$52cd:  83                  ADD      E
$52ce:  89                  ADC      C
$52cf:  02                  STAX     B
$52d0:  88                  ADC      B
$52d1:  04                  INR      B
$52d2:  86                  ADD      M
$52d3:  05                  DCR      B
$52d4:  09                  DAD      B
$52d5:  05                  DCR      B
$52d6:  0b                  DCX      B
$52d7:  04                  INR      B
$52d8:  0c                  INR      C
$52d9:  02                  STAX     B
$52da:  0c                  INR      C
$52db:  83                  ADD      E
$52dc:  c1                  POP      B
$52dd:  89                  ADC      C
$52de:  08                  NOP
$52df:  89                  ADC      C
$52e0:  86                  ADD      M
$52e1:  0c                  INR      C
$52e2:  86                  ADD      M
$52e3:  0c                  INR      C
$52e4:  02                  STAX     B
$52e5:  0b                  DCX      B
$52e6:  04                  INR      B
$52e7:  09                  DAD      B
$52e8:  05                  DCR      B
$52e9:  03                  INX      B
$52ea:  05                  DCR      B
$52eb:  01 04 00            LXI      B,$0004
$52ee:  02                  STAX     B
$52ef:  00                  NOP
$52f0:  86                  ADD      M
$52f1:  c1                  POP      B
$52f2:  89                  ADC      C
$52f3:  09                  DAD      B
$52f4:  0c                  INR      C
$52f5:  83                  ADD      E
$52f6:  0b                  DCX      B
$52f7:  85                  ADD      L
$52f8:  09                  DAD      B
$52f9:  86                  ADD      M
$52fa:  86                  ADD      M
$52fb:  86                  ADD      M
$52fc:  88                  ADC      B
$52fd:  85                  ADD      L
$52fe:  89                  ADC      C
$52ff:  83                  ADD      E
$5300:  89                  ADC      C
$5301:  02                  STAX     B
$5302:  88                  ADC      B
$5303:  04                  INR      B
$5304:  86                  ADD      M
$5305:  05                  DCR      B
$5306:  09                  DAD      B
$5307:  05                  DCR      B
$5308:  0b                  DCX      B
$5309:  04                  INR      B
$530a:  0c                  INR      C
$530b:  02                  STAX     B
$530c:  0c                  INR      C
$530d:  83                  ADD      E
$530e:  c0                  RNZ
$530f:  81                  ADD      C
$5310:  81                  ADD      C
$5311:  40                  NOP
$5312:  89                  ADC      C
$5313:  06 c1               MVI      B,$c1
$5315:  89                  ADC      C
$5316:  08                  NOP
$5317:  89                  ADC      C
$5318:  86                  ADD      M
$5319:  0c                  INR      C
$531a:  86                  ADD      M
$531b:  0c                  INR      C
$531c:  02                  STAX     B
$531d:  0b                  DCX      B
$531e:  04                  INR      B
$531f:  09                  DAD      B
$5320:  05                  DCR      B
$5321:  03                  INX      B
$5322:  05                  DCR      B
$5323:  01 04 00            LXI      B,$0004
$5326:  02                  STAX     B
$5327:  00                  NOP
$5328:  86                  ADD      M
$5329:  c0                  RNZ
$532a:  00                  NOP
$532b:  00                  NOP
$532c:  40                  NOP
$532d:  89                  ADC      C
$532e:  05                  DCR      B
$532f:  c1                  POP      B
$5330:  89                  ADC      C
$5331:  08                  NOP
$5332:  0b                  DCX      B
$5333:  05                  DCR      B
$5334:  0c                  INR      C
$5335:  03                  INX      B
$5336:  0c                  INR      C
$5337:  83                  ADD      E
$5338:  0a                  LDAX     B
$5339:  85                  ADD      L
$533a:  07                  RLC
$533b:  85                  ADD      L
$533c:  05                  DCR      B
$533d:  84                  ADD      H
$533e:  81                  ADD      C
$533f:  04                  INR      B
$5340:  84                  ADD      H
$5341:  05                  DCR      B
$5342:  87                  ADD      A
$5343:  05                  DCR      B
$5344:  89                  ADC      C
$5345:  03                  INX      B
$5346:  89                  ADC      C
$5347:  83                  ADD      E
$5348:  88                  ADC      B
$5349:  85                  ADD      L
$534a:  c1                  POP      B
$534b:  89                  ADC      C
$534c:  09                  DAD      B
$534d:  0c                  INR      C
$534e:  00                  NOP
$534f:  89                  ADC      C
$5350:  00                  NOP
$5351:  c0                  RNZ
$5352:  0c                  INR      C
$5353:  86                  ADD      M
$5354:  40                  NOP
$5355:  0c                  INR      C
$5356:  06 c1               MVI      B,$c1
$5358:  89                  ADC      C
$5359:  08                  NOP
$535a:  0c                  INR      C
$535b:  85                  ADD      L
$535c:  85                  ADD      L
$535d:  85                  ADD      L
$535e:  88                  ADC      B
$535f:  84                  ADD      H
$5360:  89                  ADC      C
$5361:  82                  ADD      D
$5362:  89                  ADC      C
$5363:  02                  STAX     B
$5364:  88                  ADC      B
$5365:  04                  INR      B
$5366:  85                  ADD      L
$5367:  05                  DCR      B
$5368:  0c                  INR      C
$5369:  05                  DCR      B
$536a:  c1                  POP      B
$536b:  89                  ADC      C
$536c:  09                  DAD      B
$536d:  0c                  INR      C
$536e:  86                  ADD      M
$536f:  89                  ADC      C
$5370:  00                  NOP
$5371:  0c                  INR      C
$5372:  06 c1               MVI      B,$c1
$5374:  89                  ADC      C
$5375:  0b                  DCX      B
$5376:  0c                  INR      C
$5377:  88                  ADC      B
$5378:  89                  ADC      C
$5379:  84                  ADD      H
$537a:  04                  INR      B
$537b:  00                  NOP
$537c:  89                  ADC      C
$537d:  04                  INR      B
$537e:  0c                  INR      C
$537f:  08                  NOP
$5380:  c1                  POP      B
$5381:  89                  ADC      C
$5382:  09                  DAD      B
$5383:  0c                  INR      C
$5384:  86                  ADD      M
$5385:  89                  ADC      C
$5386:  06 c0               MVI      B,$c0
$5388:  0c                  INR      C
$5389:  06 40               MVI      B,$40
$538b:  89                  ADC      C
$538c:  86                  ADD      M
$538d:  c1                  POP      B
$538e:  89                  ADC      C
$538f:  09                  DAD      B
$5390:  0c                  INR      C
$5391:  86                  ADD      M
$5392:  01 00 0c            LXI      B,$0c00
$5395:  06 c0               MVI      B,$c0
$5397:  01 00 40            LXI      B,$4000
$539a:  89                  ADC      C
$539b:  00                  NOP
$539c:  c1                  POP      B
$539d:  89                  ADC      C
$539e:  08                  NOP
$539f:  0c                  INR      C
$53a0:  85                  ADD      L
$53a1:  0c                  INR      C
$53a2:  05                  DCR      B
$53a3:  89                  ADC      C
$53a4:  85                  ADD      L
$53a5:  89                  ADC      C
$53a6:  05                  DCR      B
$53a7:  c1                  POP      B
$53a8:  89                  ADC      C
$53a9:  05                  DCR      B
$53aa:  0f                  RRC
$53ab:  02                  STAX     B
$53ac:  0f                  RRC
$53ad:  82                  ADD      D
$53ae:  8b                  ADC      E
$53af:  82                  ADD      D
$53b0:  8b                  ADC      E
$53b1:  02                  STAX     B
$53b2:  c1                  POP      B
$53b3:  89                  ADC      C
$53b4:  0a                  LDAX     B
$53b5:  10                  NOP
$53b6:  87                  ADD      A
$53b7:  8e                  ADC      M
$53b8:  07                  RLC
$53b9:  c1                  POP      B
$53ba:  89                  ADC      C
$53bb:  05                  DCR      B
$53bc:  0f                  RRC
$53bd:  82                  ADD      D
$53be:  0f                  RRC
$53bf:  02                  STAX     B
$53c0:  8b                  ADC      E
$53c1:  02                  STAX     B
$53c2:  8b                  ADC      E
$53c3:  82                  ADD      D
$53c4:  c1                  POP      B
$53c5:  89                  ADC      C
$53c6:  08                  NOP
$53c7:  0a                  LDAX     B
$53c8:  85                  ADD      L
$53c9:  10                  NOP
$53ca:  00                  NOP
$53cb:  0a                  LDAX     B
$53cc:  05                  DCR      B
$53cd:  c1                  POP      B
$53ce:  89                  ADC      C
$53cf:  08                  NOP
$53d0:  89                  ADC      C
$53d1:  85                  ADD      L
$53d2:  89                  ADC      C
$53d3:  05                  DCR      B
$53d4:  c1                  POP      B
$53d5:  89                  ADC      C
$53d6:  03                  INX      B
$53d7:  0c                  INR      C
$53d8:  00                  NOP
$53d9:  07                  RLC
$53da:  00                  NOP
$53db:  0c                  INR      C
$53dc:  81                  ADD      C
$53dd:  0c                  INR      C
$53de:  00                  NOP
$53df:  c1                  POP      B
$53e0:  89                  ADC      C
$53e1:  07                  RLC
$53e2:  0c                  INR      C
$53e3:  85                  ADD      L
$53e4:  89                  ADC      C
$53e5:  85                  ADD      L
$53e6:  89                  ADC      C
$53e7:  01 88 03            LXI      B,$0388
$53ea:  86                  ADD      M
$53eb:  04                  INR      B
$53ec:  02                  STAX     B
$53ed:  04                  INR      B
$53ee:  04                  INR      B
$53ef:  03                  INX      B
$53f0:  05                  DCR      B
$53f1:  01 05 85            LXI      B,$8505
$53f4:  c1                  POP      B
$53f5:  89                  ADC      C
$53f6:  06 05               MVI      B,$05
$53f8:  03                  INX      B
$53f9:  05                  DCR      B
$53fa:  81                  ADD      C
$53fb:  04                  INR      B
$53fc:  83                  ADD      E
$53fd:  02                  STAX     B
$53fe:  84                  ADD      H
$53ff:  86                  ADD      M
$5400:  84                  ADD      H
$5401:  88                  ADC      B
$5402:  83                  ADD      E
$5403:  89                  ADC      C
$5404:  81                  ADD      C
$5405:  89                  ADC      C
$5406:  03                  INX      B
$5407:  c1                  POP      B
$5408:  89                  ADC      C
$5409:  07                  RLC
$540a:  05                  DCR      B
$540b:  04                  INR      B
$540c:  05                  DCR      B
$540d:  82                  ADD      D
$540e:  04                  INR      B
$540f:  84                  ADD      H
$5410:  02                  STAX     B
$5411:  85                  ADD      L
$5412:  86                  ADD      M
$5413:  85                  ADD      L
$5414:  88                  ADC      B
$5415:  84                  ADD      H
$5416:  89                  ADC      C
$5417:  82                  ADD      D
$5418:  89                  ADC      C
$5419:  04                  INR      B
$541a:  0c                  INR      C
$541b:  04                  INR      B
$541c:  c1                  POP      B
$541d:  89                  ADC      C
$541e:  07                  RLC
$541f:  82                  ADD      D
$5420:  85                  ADD      L
$5421:  82                  ADD      D
$5422:  04                  INR      B
$5423:  02                  STAX     B
$5424:  04                  INR      B
$5425:  04                  INR      B
$5426:  03                  INX      B
$5427:  05                  DCR      B
$5428:  01 05 82            LXI      B,$8205
$542b:  04                  INR      B
$542c:  84                  ADD      H
$542d:  02                  STAX     B
$542e:  85                  ADD      L
$542f:  86                  ADD      M
$5430:  85                  ADD      L
$5431:  88                  ADC      B
$5432:  84                  ADD      H
$5433:  89                  ADC      C
$5434:  82                  ADD      D
$5435:  89                  ADC      C
$5436:  04                  INR      B
$5437:  c1                  POP      B
$5438:  86                  ADD      M
$5439:  06 0c               MVI      B,$0c
$543b:  03                  INX      B
$543c:  0c                  INR      C
$543d:  02                  STAX     B
$543e:  0b                  DCX      B
$543f:  00                  NOP
$5440:  09                  DAD      B
$5441:  81                  ADD      C
$5442:  89                  ADC      C
$5443:  81                  ADD      C
$5444:  c0                  RNZ
$5445:  05                  DCR      B
$5446:  83                  ADD      E
$5447:  40                  NOP
$5448:  05                  DCR      B
$5449:  03                  INX      B
$544a:  c1                  POP      B
$544b:  89                  ADC      C
$544c:  07                  RLC
$544d:  89                  ADC      C
$544e:  04                  INR      B
$544f:  05                  DCR      B
$5450:  04                  INR      B
$5451:  05                  DCR      B
$5452:  82                  ADD      D
$5453:  04                  INR      B
$5454:  84                  ADD      H
$5455:  02                  STAX     B
$5456:  85                  ADD      L
$5457:  86                  ADD      M
$5458:  85                  ADD      L
$5459:  88                  ADC      B
$545a:  84                  ADD      H
$545b:  89                  ADC      C
$545c:  82                  ADD      D
$545d:  89                  ADC      C
$545e:  04                  INR      B
$545f:  8d                  ADC      L
$5460:  04                  INR      B
$5461:  8f                  ADC      A
$5462:  03                  INX      B
$5463:  90                  SUB      B
$5464:  01 90 85            LXI      B,$8590
$5467:  c1                  POP      B
$5468:  89                  ADC      C
$5469:  07                  RLC
$546a:  0c                  INR      C
$546b:  85                  ADD      L
$546c:  89                  ADC      C
$546d:  85                  ADD      L
$546e:  c0                  RNZ
$546f:  05                  DCR      B
$5470:  85                  ADD      L
$5471:  40                  NOP
$5472:  05                  DCR      B
$5473:  01 04 03            LXI      B,$0304
$5476:  02                  STAX     B
$5477:  04                  INR      B
$5478:  89                  ADC      C
$5479:  04                  INR      B
$547a:  c1                  POP      B
$547b:  89                  ADC      C
$547c:  03                  INX      B
$547d:  05                  DCR      B
$547e:  00                  NOP
$547f:  89                  ADC      C
$5480:  00                  NOP
$5481:  c0                  RNZ
$5482:  0c                  INR      C
$5483:  00                  NOP
$5484:  40                  NOP
$5485:  c1                  POP      B
$5486:  89                  ADC      C
$5487:  05                  DCR      B
$5488:  05                  DCR      B
$5489:  02                  STAX     B
$548a:  8d                  ADC      L
$548b:  02                  STAX     B
$548c:  8f                  ADC      A
$548d:  01 90 81            LXI      B,$8190
$5490:  90                  SUB      B
$5491:  82                  ADD      D
$5492:  c0                  RNZ
$5493:  0b                  DCX      B
$5494:  02                  STAX     B
$5495:  40                  NOP
$5496:  0c                  INR      C
$5497:  01 0d 02            LXI      B,$020d
$549a:  0c                  INR      C
$549b:  03                  INX      B
$549c:  0b                  DCX      B
$549d:  02                  STAX     B
$549e:  c1                  POP      B
$549f:  89                  ADC      C
$54a0:  08                  NOP
$54a1:  0c                  INR      C
$54a2:  85                  ADD      L
$54a3:  89                  ADC      C
$54a4:  85                  ADD      L
$54a5:  c0                  RNZ
$54a6:  05                  DCR      B
$54a7:  05                  DCR      B
$54a8:  40                  NOP
$54a9:  83                  ADD      E
$54aa:  85                  ADD      L
$54ab:  c0                  RNZ
$54ac:  81                  ADD      C
$54ad:  82                  ADD      D
$54ae:  40                  NOP
$54af:  89                  ADC      C
$54b0:  05                  DCR      B
$54b1:  c1                  POP      B
$54b2:  89                  ADC      C
$54b3:  05                  DCR      B
$54b4:  0c                  INR      C
$54b5:  82                  ADD      D
$54b6:  86                  ADD      M
$54b7:  82                  ADD      D
$54b8:  88                  ADC      B
$54b9:  81                  ADD      C
$54ba:  89                  ADC      C
$54bb:  01 89 02            LXI      B,$0289
$54be:  c1                  POP      B
$54bf:  89                  ADC      C
$54c0:  09                  DAD      B
$54c1:  89                  ADC      C
$54c2:  86                  ADD      M
$54c3:  05                  DCR      B
$54c4:  86                  ADD      M
$54c5:  05                  DCR      B
$54c6:  03                  INX      B
$54c7:  04                  INR      B
$54c8:  05                  DCR      B
$54c9:  02                  STAX     B
$54ca:  06 89               MVI      B,$89
$54cc:  06 c0               MVI      B,$c0
$54ce:  05                  DCR      B
$54cf:  00                  NOP
$54d0:  40                  NOP
$54d1:  89                  ADC      C
$54d2:  00                  NOP
$54d3:  c1                  POP      B
$54d4:  89                  ADC      C
$54d5:  07                  RLC
$54d6:  89                  ADC      C
$54d7:  85                  ADD      L
$54d8:  05                  DCR      B
$54d9:  85                  ADD      L
$54da:  05                  DCR      B
$54db:  01 04 03            LXI      B,$0304
$54de:  02                  STAX     B
$54df:  04                  INR      B
$54e0:  89                  ADC      C
$54e1:  04                  INR      B
$54e2:  c1                  POP      B
$54e3:  89                  ADC      C
$54e4:  07                  RLC
$54e5:  89                  ADC      C
$54e6:  85                  ADD      L
$54e7:  89                  ADC      C
$54e8:  01 88 03            LXI      B,$0388
$54eb:  86                  ADD      M
$54ec:  04                  INR      B
$54ed:  02                  STAX     B
$54ee:  04                  INR      B
$54ef:  04                  INR      B
$54f0:  03                  INX      B
$54f1:  05                  DCR      B
$54f2:  01 05 85            LXI      B,$8505
$54f5:  90                  SUB      B
$54f6:  85                  ADD      L
$54f7:  c1                  POP      B
$54f8:  89                  ADC      C
$54f9:  07                  RLC
$54fa:  05                  DCR      B
$54fb:  01 05 82            LXI      B,$8205
$54fe:  04                  INR      B
$54ff:  84                  ADD      H
$5500:  02                  STAX     B
$5501:  85                  ADD      L
$5502:  86                  ADD      M
$5503:  85                  ADD      L
$5504:  88                  ADC      B
$5505:  84                  ADD      H
$5506:  89                  ADC      C
$5507:  82                  ADD      D
$5508:  89                  ADC      C
$5509:  01 88 03            LXI      B,$0388
$550c:  86                  ADD      M
$550d:  04                  INR      B
$550e:  02                  STAX     B
$550f:  04                  INR      B
$5510:  04                  INR      B
$5511:  03                  INX      B
$5512:  05                  DCR      B
$5513:  01 c1 89            LXI      B,$89c1
$5516:  07                  RLC
$5517:  90                  SUB      B
$5518:  04                  INR      B
$5519:  05                  DCR      B
$551a:  04                  INR      B
$551b:  05                  DCR      B
$551c:  82                  ADD      D
$551d:  04                  INR      B
$551e:  84                  ADD      H
$551f:  02                  STAX     B
$5520:  85                  ADD      L
$5521:  86                  ADD      M
$5522:  85                  ADD      L
$5523:  88                  ADC      B
$5524:  84                  ADD      H
$5525:  89                  ADC      C
$5526:  82                  ADD      D
$5527:  89                  ADC      C
$5528:  04                  INR      B
$5529:  c1                  POP      B
$552a:  89                  ADC      C
$552b:  06 03               MVI      B,$03
$552d:  03                  INX      B
$552e:  04                  INR      B
$552f:  02                  STAX     B
$5530:  05                  DCR      B
$5531:  00                  NOP
$5532:  05                  DCR      B
$5533:  84                  ADD      H
$5534:  89                  ADC      C
$5535:  84                  ADD      H
$5536:  c1                  POP      B
$5537:  89                  ADC      C
$5538:  08                  NOP
$5539:  03                  INX      B
$553a:  04                  INR      B
$553b:  05                  DCR      B
$553c:  02                  STAX     B
$553d:  05                  DCR      B
$553e:  82                  ADD      D
$553f:  04                  INR      B
$5540:  84                  ADD      H
$5541:  02                  STAX     B
$5542:  85                  ADD      L
$5543:  00                  NOP
$5544:  84                  ADD      H
$5545:  84                  ADD      H
$5546:  03                  INX      B
$5547:  85                  ADD      L
$5548:  04                  INR      B
$5549:  86                  ADD      M
$554a:  05                  DCR      B
$554b:  88                  ADC      B
$554c:  04                  INR      B
$554d:  89                  ADC      C
$554e:  02                  STAX     B
$554f:  89                  ADC      C
$5550:  83                  ADD      E
$5551:  87                  ADD      A
$5552:  85                  ADD      L
$5553:  c1                  POP      B
$5554:  89                  ADC      C
$5555:  06 0c               MVI      B,$0c
$5557:  00                  NOP
$5558:  89                  ADC      C
$5559:  00                  NOP
$555a:  c0                  RNZ
$555b:  05                  DCR      B
$555c:  82                  ADD      D
$555d:  40                  NOP
$555e:  05                  DCR      B
$555f:  04                  INR      B
$5560:  c1                  POP      B
$5561:  89                  ADC      C
$5562:  07                  RLC
$5563:  05                  DCR      B
$5564:  85                  ADD      L
$5565:  86                  ADD      M
$5566:  85                  ADD      L
$5567:  88                  ADC      B
$5568:  84                  ADD      H
$5569:  89                  ADC      C
$556a:  82                  ADD      D
$556b:  89                  ADC      C
$556c:  04                  INR      B
$556d:  05                  DCR      B
$556e:  04                  INR      B
$556f:  c1                  POP      B
$5570:  89                  ADC      C
$5571:  08                  NOP
$5572:  05                  DCR      B
$5573:  85                  ADD      L
$5574:  89                  ADC      C
$5575:  00                  NOP
$5576:  05                  DCR      B
$5577:  05                  DCR      B
$5578:  c1                  POP      B
$5579:  89                  ADC      C
$557a:  08                  NOP
$557b:  05                  DCR      B
$557c:  86                  ADD      M
$557d:  89                  ADC      C
$557e:  83                  ADD      E
$557f:  81                  ADD      C
$5580:  00                  NOP
$5581:  89                  ADC      C
$5582:  03                  INX      B
$5583:  05                  DCR      B
$5584:  06 c1               MVI      B,$c1
$5586:  89                  ADC      C
$5587:  07                  RLC
$5588:  05                  DCR      B
$5589:  85                  ADD      L
$558a:  89                  ADC      C
$558b:  04                  INR      B
$558c:  c0                  RNZ
$558d:  05                  DCR      B
$558e:  04                  INR      B
$558f:  40                  NOP
$5590:  89                  ADC      C
$5591:  85                  ADD      L
$5592:  c1                  POP      B
$5593:  89                  ADC      C
$5594:  07                  RLC
$5595:  05                  DCR      B
$5596:  85                  ADD      L
$5597:  88                  ADC      B
$5598:  00                  NOP
$5599:  c0                  RNZ
$559a:  05                  DCR      B
$559b:  04                  INR      B
$559c:  40                  NOP
$559d:  8f                  ADC      A
$559e:  82                  ADD      D
$559f:  90                  SUB      B
$55a0:  83                  ADD      E
$55a1:  90                  SUB      B
$55a2:  85                  ADD      L
$55a3:  c1                  POP      B
$55a4:  89                  ADC      C
$55a5:  07                  RLC
$55a6:  05                  DCR      B
$55a7:  85                  ADD      L
$55a8:  05                  DCR      B
$55a9:  04                  INR      B
$55aa:  89                  ADC      C
$55ab:  85                  ADD      L
$55ac:  89                  ADC      C
$55ad:  04                  INR      B
$55ae:  c1                  POP      B
$55af:  89                  ADC      C
$55b0:  05                  DCR      B
$55b1:  0f                  RRC
$55b2:  02                  STAX     B
$55b3:  0f                  RRC
$55b4:  01 0e 00            LXI      B,$000e
$55b7:  0c                  INR      C
$55b8:  81                  ADD      C
$55b9:  03                  INX      B
$55ba:  81                  ADD      C
$55bb:  02                  STAX     B
$55bc:  82                  ADD      D
$55bd:  01 81 88            LXI      B,$8881
$55c0:  81                  ADD      C
$55c1:  8a                  ADC      D
$55c2:  00                  NOP
$55c3:  8b                  ADC      E
$55c4:  01 8b 02            LXI      B,$028b
$55c7:  c1                  POP      B
$55c8:  89                  ADC      C
$55c9:  03                  INX      B
$55ca:  0f                  RRC
$55cb:  00                  NOP
$55cc:  8d                  ADC      L
$55cd:  00                  NOP
$55ce:  c1                  POP      B
$55cf:  89                  ADC      C
$55d0:  05                  DCR      B
$55d1:  0f                  RRC
$55d2:  82                  ADD      D
$55d3:  0f                  RRC
$55d4:  81                  ADD      C
$55d5:  0e 00               MVI      C,$00
$55d7:  0c                  INR      C
$55d8:  01 03 01            LXI      B,$0103
$55db:  02                  STAX     B
$55dc:  02                  STAX     B
$55dd:  01 01 88            LXI      B,$8801
$55e0:  01 8a 00            LXI      B,$008a
$55e3:  8b                  ADC      E
$55e4:  81                  ADD      C
$55e5:  8b                  ADC      E
$55e6:  82                  ADD      D
$55e7:  c1                  POP      B
$55e8:  89                  ADC      C
$55e9:  08                  NOP
$55ea:  0c                  INR      C
$55eb:  85                  ADD      L
$55ec:  0c                  INR      C
$55ed:  05                  DCR      B
$55ee:  c1                  POP      B
$55ef:  00                  NOP
$55f0:  f0                  RP
$55f1:  00                  NOP
$55f2:  f7                  RST      6
$55f3:  03                  INX      B
$55f4:  00                  NOP
$55f5:  f4 31 00            CP       $0031
$55f8:  fd                  NOP
$55f9:  88                  ADC      B
$55fa:  13                  INX      D
$55fb:  00                  NOP
$55fc:  f1                  POP      PSW
$55fd:  00                  NOP
$55fe:  00                  NOP
$55ff:  00                  NOP
$5600:  00                  NOP
$5601:  00                  NOP
$5602:  fa 76 00            JM       $0076
$5605:  f2 a0 41            JP       $41a0
$5608:  00                  NOP
$5609:  00                  NOP
$560a:  a0                  ANA      B
$560b:  41                  MOV      B,C
$560c:  68                  MOV      L,B
$560d:  2e 00               MVI      L,$00
$560f:  00                  NOP
$5610:  68                  MOV      L,B
$5611:  2e 00               MVI      L,$00
$5613:  00                  NOP
$5614:  00                  NOP
$5615:  00                  NOP
$5616:  00                  NOP
$5617:  fa a5 00            JM       $00a5
$561a:  fd                  NOP
$561b:  b8                  CMP      B
$561c:  0b                  DCX      B
$561d:  00                  NOP
$561e:  f1                  POP      PSW
$561f:  90                  SUB      B
$5620:  01 90 01            LXI      B,$0190
$5623:  00                  NOP
$5624:  f2 60 09            JP       $0960
$5627:  90                  SUB      B
$5628:  01 00 f1            LXI      B,$f100
$562b:  90                  SUB      B
$562c:  01 90 01            LXI      B,$0190
$562f:  00                  NOP
$5630:  f2 60 09            JP       $0960
$5633:  c0                  RNZ
$5634:  03                  INX      B
$5635:  00                  NOP
$5636:  f1                  POP      PSW
$5637:  90                  SUB      B
$5638:  01 90 01            LXI      B,$0190
$563b:  00                  NOP
$563c:  f2 60 09            JP       $0960
$563f:  f0                  RP
$5640:  05                  DCR      B
$5641:  00                  NOP
$5642:  f1                  POP      PSW
$5643:  90                  SUB      B
$5644:  01 90 01            LXI      B,$0190
$5647:  00                  NOP
$5648:  f2 60 09            JP       $0960
$564b:  60                  MOV      H,B
$564c:  09                  DAD      B
$564d:  00                  NOP
$564e:  f1                  POP      PSW
$564f:  90                  SUB      B
$5650:  01 90 01            LXI      B,$0190
$5653:  00                  NOP
$5654:  f2 f0 05            JP       $05f0
$5657:  60                  MOV      H,B
$5658:  09                  DAD      B
$5659:  00                  NOP
$565a:  f1                  POP      PSW
$565b:  90                  SUB      B
$565c:  01 90 01            LXI      B,$0190
$565f:  00                  NOP
$5660:  f2 c0 03            JP       $03c0
$5663:  60                  MOV      H,B
$5664:  09                  DAD      B
$5665:  00                  NOP
$5666:  f1                  POP      PSW
$5667:  90                  SUB      B
$5668:  01 90 01            LXI      B,$0190
$566b:  00                  NOP
$566c:  f2 90 01            JP       $0190
$566f:  60                  MOV      H,B
$5670:  09                  DAD      B
$5671:  00                  NOP
$5672:  f1                  POP      PSW
$5673:  90                  SUB      B
$5674:  01 d8 2c            LXI      B,$2cd8
$5677:  00                  NOP
$5678:  f2 90 01            JP       $0190
$567b:  08                  NOP
$567c:  25                  DCR      H
$567d:  00                  NOP
$567e:  f1                  POP      PSW
$567f:  90                  SUB      B
$5680:  01 d8 2c            LXI      B,$2cd8
$5683:  00                  NOP
$5684:  f2 c0 03            JP       $03c0
$5687:  08                  NOP
$5688:  25                  DCR      H
$5689:  00                  NOP
$568a:  f1                  POP      PSW
$568b:  90                  SUB      B
$568c:  01 d8 2c            LXI      B,$2cd8
$568f:  00                  NOP
$5690:  f2 f0 05            JP       $05f0
$5693:  08                  NOP
$5694:  25                  DCR      H
$5695:  00                  NOP
$5696:  f1                  POP      PSW
$5697:  90                  SUB      B
$5698:  01 d8 2c            LXI      B,$2cd8
$569b:  00                  NOP
$569c:  f2 60 09            JP       $0960
$569f:  08                  NOP
$56a0:  25                  DCR      H
$56a1:  00                  NOP
$56a2:  f1                  POP      PSW
$56a3:  90                  SUB      B
$56a4:  01 d8 2c            LXI      B,$2cd8
$56a7:  00                  NOP
$56a8:  f2 60 09            JP       $0960
$56ab:  78                  MOV      A,B
$56ac:  28                  NOP
$56ad:  00                  NOP
$56ae:  f1                  POP      PSW
$56af:  90                  SUB      B
$56b0:  01 d8 2c            LXI      B,$2cd8
$56b3:  00                  NOP
$56b4:  f2 60 09            JP       $0960
$56b7:  a8                  XRA      B
$56b8:  2a 00 f1            LHLD     $f100
$56bb:  90                  SUB      B
$56bc:  01 d8 2c            LXI      B,$2cd8
$56bf:  00                  NOP
$56c0:  f2 60 09            JP       $0960
$56c3:  d8                  RC
$56c4:  2c                  INR      L
$56c5:  00                  NOP
$56c6:  f1                  POP      PSW
$56c7:  10                  NOP
$56c8:  40                  NOP
$56c9:  d8                  RC
$56ca:  2c                  INR      L
$56cb:  00                  NOP
$56cc:  f2 10 40            JP       $4010
$56cf:  08                  NOP
$56d0:  25                  DCR      H
$56d1:  00                  NOP
$56d2:  f1                  POP      PSW
$56d3:  10                  NOP
$56d4:  40                  NOP
$56d5:  d8                  RC
$56d6:  2c                  INR      L
$56d7:  00                  NOP
$56d8:  f2 e0 3d            JP       $3de0
$56db:  08                  NOP
$56dc:  25                  DCR      H
$56dd:  00                  NOP
$56de:  f1                  POP      PSW
$56df:  10                  NOP
$56e0:  40                  NOP
$56e1:  d8                  RC
$56e2:  2c                  INR      L
$56e3:  00                  NOP
$56e4:  f2 b0 3b            JP       $3bb0
$56e7:  08                  NOP
$56e8:  25                  DCR      H
$56e9:  00                  NOP
$56ea:  f1                  POP      PSW
$56eb:  10                  NOP
$56ec:  40                  NOP
$56ed:  d8                  RC
$56ee:  2c                  INR      L
$56ef:  00                  NOP
$56f0:  f2 40 38            JP       $3840
$56f3:  08                  NOP
$56f4:  25                  DCR      H
$56f5:  00                  NOP
$56f6:  f1                  POP      PSW
$56f7:  10                  NOP
$56f8:  40                  NOP
$56f9:  d8                  RC
$56fa:  2c                  INR      L
$56fb:  00                  NOP
$56fc:  f2 40 38            JP       $3840
$56ff:  28                  NOP
$5700:  28                  NOP
$5701:  00                  NOP
$5702:  f1                  POP      PSW
$5703:  10                  NOP
$5704:  40                  NOP
$5705:  d8                  RC
$5706:  2c                  INR      L
$5707:  00                  NOP
$5708:  f2 40 38            JP       $3840
$570b:  a8                  XRA      B
$570c:  2a 00 f1            LHLD     $f100
$570f:  10                  NOP
$5710:  40                  NOP
$5711:  d8                  RC
$5712:  2c                  INR      L
$5713:  00                  NOP
$5714:  f2 40 38            JP       $3840
$5717:  d8                  RC
$5718:  2c                  INR      L
$5719:  00                  NOP
$571a:  f1                  POP      PSW
$571b:  10                  NOP
$571c:  40                  NOP
$571d:  90                  SUB      B
$571e:  01 00 f2            LXI      B,$f200
$5721:  40                  NOP
$5722:  38                  NOP
$5723:  90                  SUB      B
$5724:  01 00 f1            LXI      B,$f100
$5727:  10                  NOP
$5728:  40                  NOP
$5729:  90                  SUB      B
$572a:  01 00 f2            LXI      B,$f200
$572d:  40                  NOP
$572e:  38                  NOP
$572f:  c0                  RNZ
$5730:  03                  INX      B
$5731:  00                  NOP
$5732:  f1                  POP      PSW
$5733:  10                  NOP
$5734:  40                  NOP
$5735:  90                  SUB      B
$5736:  01 00 f2            LXI      B,$f200
$5739:  40                  NOP
$573a:  38                  NOP
$573b:  f0                  RP
$573c:  05                  DCR      B
$573d:  00                  NOP
$573e:  f1                  POP      PSW
$573f:  10                  NOP
$5740:  40                  NOP
$5741:  90                  SUB      B
$5742:  01 00 f2            LXI      B,$f200
$5745:  40                  NOP
$5746:  38                  NOP
$5747:  60                  MOV      H,B
$5748:  09                  DAD      B
$5749:  00                  NOP
$574a:  f1                  POP      PSW
$574b:  10                  NOP
$574c:  40                  NOP
$574d:  90                  SUB      B
$574e:  01 00 f2            LXI      B,$f200
$5751:  b0                  ORA      B
$5752:  3b                  DCX      SP
$5753:  60                  MOV      H,B
$5754:  09                  DAD      B
$5755:  00                  NOP
$5756:  f1                  POP      PSW
$5757:  10                  NOP
$5758:  40                  NOP
$5759:  90                  SUB      B
$575a:  01 00 f2            LXI      B,$f200
$575d:  e0                  RPO
$575e:  3d                  DCR      A
$575f:  60                  MOV      H,B
$5760:  09                  DAD      B
$5761:  00                  NOP
$5762:  f1                  POP      PSW
$5763:  10                  NOP
$5764:  40                  NOP
$5765:  90                  SUB      B
$5766:  01 00 f2            LXI      B,$f200
$5769:  10                  NOP
$576a:  40                  NOP
$576b:  60                  MOV      H,B
$576c:  09                  DAD      B
$576d:  00                  NOP
$576e:  f2 10 40            JP       $4010
$5771:  90                  SUB      B
$5772:  01 00 f4            LXI      B,$f400
$5775:  32 00 f1            STA      $f100
$5778:  50                  MOV      D,B
$5779:  14                  INR      D
$577a:  48                  MOV      C,B
$577b:  2b                  DCX      H
$577c:  00                  NOP
$577d:  fe 02               CPI      $02
$577f:  00                  NOP
$5780:  fb                  EI
$5781:  00                  NOP
$5782:  f3                  DI
$5783:  01 00 00            LXI      B,$0000
$5786:  00                  NOP
$5787:  00                  NOP
$5788:  f5                  PUSH     PSW
$5789:  1e 85               MVI      E,$85
$578b:  00                  NOP
$578c:  00                  NOP
$578d:  00                  NOP
$578e:  00                  NOP
$578f:  01 00 00            LXI      B,$0000
$5792:  fd                  NOP
$5793:  64                  NOP
$5794:  00                  NOP
$5795:  00                  NOP
$5796:  fa c1 00            JM       $00c1
$5799:  f6 c2               ORI      $c2
$579b:  20                  NOP
$579c:  b5                  ORA      L
$579d:  20                  NOP
$579e:  c1                  POP      B
$579f:  20                  NOP
$57a0:  c2 20 20            JNZ      $2020
$57a3:  b0                  ORA      B
$57a4:  20                  NOP
$57a5:  b2                  ORA      D
$57a6:  20                  NOP
$57a7:  c2 20 be            JNZ      $be20
$57aa:  20                  NOP
$57ab:  b3                  ORA      E
$57ac:  20                  NOP
$57ad:  c0                  RNZ
$57ae:  20                  NOP
$57af:  b0                  ORA      B
$57b0:  20                  NOP
$57b1:  c4 20 38            CNZ      $3820
$57b4:  38                  NOP
$57b5:  32 2e 30            STA      $302e
$57b8:  31 03 00            LXI      SP,$0003
$57bb:  f1                  POP      PSW
$57bc:  e8                  RPE
$57bd:  03                  INX      B
$57be:  00                  NOP
$57bf:  1e 00               MVI      E,$00
$57c1:  f6 c2               ORI      $c2
$57c3:  20                  NOP
$57c4:  b8                  CMP      B
$57c5:  20                  NOP
$57c6:  bf                  CMP      A
$57c7:  20                  NOP
$57c8:  cb 20 20            JMP      $2020
$57cb:  bb           DB  $bb
$57cc:  20           DB  $20
$57cd:  b8           DB  $b8
$57ce:  20           DB  $20
$57cf:  bd           DB  $bd
$57d0:  20           DB  $20
$57d1:  b8           DB  $b8
$57d2:  20           DB  $20
$57d3:  b9           DB  $b9
$57d4:  03           DB  $03
$57d5:  00           DB  $00
$57d6:  f1           DB  $f1
$57d7:  58           DB  $58
$57d8:  02           DB  $02
$57d9:  58           DB  $58
$57da:  1b           DB  $1b
$57db:  00           DB  $00
$57dc:  f6           DB  $f6
$57dd:  c1           DB  $c1
$57de:  20           DB  $20
$57df:  bc           DB  $bc
$57e0:  20           DB  $20
$57e1:  b5           DB  $b5
$57e2:  20           DB  $20
$57e3:  bd           DB  $bd
$57e4:  20           DB  $20
$57e5:  b0           DB  $b0
$57e6:  20           DB  $20
$57e7:  20           DB  $20
$57e8:  bf           DB  $bf
$57e9:  20           DB  $20
$57ea:  b5           DB  $b5
$57eb:  20           DB  $20
$57ec:  c0           DB  $c0
$57ed:  20           DB  $20
$57ee:  cc           DB  $cc
$57ef:  20           DB  $20
$57f0:  b5           DB  $b5
$57f1:  20           DB  $20
$57f2:  b2           DB  $b2
$57f3:  03           DB  $03
$57f4:  00           DB  $00
$57f5:  f1           DB  $f1
$57f6:  d4           DB  $d4
$57f7:  17           DB  $17
$57f8:  40           DB  $40
$57f9:  1f           DB  $1f
$57fa:  00           DB  $00
$57fb:  f6           DB  $f6
$57fc:  be           DB  $be
$57fd:  ba           DB  $ba
$57fe:  c0           DB  $c0
$57ff:  c3           DB  $c3
$5800:  b6           DB  $b6
$5801:  bd           DB  $bd
$5802:  be           DB  $be
$5803:  c1           DB  $c1
$5804:  c2           DB  $c2
$5805:  b8           DB  $b8
$5806:  2e           DB  $2e
$5807:  20           DB  $20
$5808:  b4           DB  $b4
$5809:  c3           DB  $c3
$580a:  b3           DB  $b3
$580b:  b8           DB  $b8
$580c:  03           DB  $03
$580d:  00           DB  $00
$580e:  f1           DB  $f1
$580f:  e0           DB  $e0
$5810:  2e           DB  $2e
$5811:  10           DB  $10
$5812:  1d           DB  $1d
$5813:  00           DB  $00
$5814:  f6           DB  $f6
$5815:  c8           DB  $c8
$5816:  20           DB  $20
$5817:  c0           DB  $c0
$5818:  20           DB  $20
$5819:  b8           DB  $b8
$581a:  20           DB  $20
$581b:  c4           DB  $c4
$581c:  20           DB  $20
$581d:  c2           DB  $c2
$581e:  20           DB  $20
$581f:  cb           DB  $cb
$5820:  03           DB  $03
$5821:  00           DB  $00
$5822:  f4           DB  $f4
$5823:  33           DB  $33
$5824:  00           DB  $00
$5825:  f5           DB  $f5
$5826:  66           DB  $66
$5827:  66           DB  $66
$5828:  00           DB  $00
$5829:  00           DB  $00
$582a:  51           DB  $51
$582b:  b8           DB  $b8
$582c:  00           DB  $00
$582d:  00           DB  $00
$582e:  00           DB  $00
$582f:  f1           DB  $f1
$5830:  30           DB  $30
$5831:  2a           DB  $2a
$5832:  c8           DB  $c8
$5833:  19           DB  $19
$5834:  00           DB  $00
$5835:  f6           DB  $f6
$5836:  41           DB  $41
$5837:  42           DB  $42
$5838:  43           DB  $43
$5839:  44           DB  $44
$583a:  45           DB  $45
$583b:  46           DB  $46
$583c:  47           DB  $47
$583d:  48           DB  $48
$583e:  49           DB  $49
$583f:  4a           DB  $4a
$5840:  4b           DB  $4b
$5841:  4c           DB  $4c
$5842:  4d           DB  $4d
$5843:  4e           DB  $4e
$5844:  4f           DB  $4f
$5845:  50           DB  $50
$5846:  51           DB  $51
$5847:  52           DB  $52
$5848:  53           DB  $53
$5849:  54           DB  $54
$584a:  55           DB  $55
$584b:  56           DB  $56
$584c:  57           DB  $57
$584d:  58           DB  $58
$584e:  59           DB  $59
$584f:  5a           DB  $5a
$5850:  5b           DB  $5b
$5851:  5c           DB  $5c
$5852:  5d           DB  $5d
$5853:  5e           DB  $5e
$5854:  40           DB  $40
$5855:  0d           DB  $0d
$5856:  0a           DB  $0a
$5857:  b0           DB  $b0
$5858:  b1           DB  $b1
$5859:  c6           DB  $c6
$585a:  b4           DB  $b4
$585b:  b5           DB  $b5
$585c:  c4           DB  $c4
$585d:  b3           DB  $b3
$585e:  c5           DB  $c5
$585f:  b8           DB  $b8
$5860:  b9           DB  $b9
$5861:  ba           DB  $ba
$5862:  bb           DB  $bb
$5863:  bc           DB  $bc
$5864:  bd           DB  $bd
$5865:  be           DB  $be
$5866:  bf           DB  $bf
$5867:  cf           DB  $cf
$5868:  c0           DB  $c0
$5869:  c1           DB  $c1
$586a:  c2           DB  $c2
$586b:  c3           DB  $c3
$586c:  b6           DB  $b6
$586d:  b2           DB  $b2
$586e:  cc           DB  $cc
$586f:  cb           DB  $cb
$5870:  b7           DB  $b7
$5871:  c8           DB  $c8
$5872:  cd           DB  $cd
$5873:  c9           DB  $c9
$5874:  c7           DB  $c7
$5875:  ce           DB  $ce
$5876:  0d           DB  $0d
$5877:  0a           DB  $0a
$5878:  21           DB  $21
$5879:  22           DB  $22
$587a:  23           DB  $23
$587b:  fd           DB  $fd
$587c:  25           DB  $25
$587d:  26           DB  $26
$587e:  27           DB  $27
$587f:  28           DB  $28
$5880:  29           DB  $29
$5881:  2a           DB  $2a
$5882:  2b           DB  $2b
$5883:  2c           DB  $2c
$5884:  2d           DB  $2d
$5885:  2e           DB  $2e
$5886:  2f           DB  $2f
$5887:  30           DB  $30
$5888:  31           DB  $31
$5889:  32           DB  $32
$588a:  33           DB  $33
$588b:  34           DB  $34
$588c:  35           DB  $35
$588d:  36           DB  $36
$588e:  37           DB  $37
$588f:  38           DB  $38
$5890:  39           DB  $39
$5891:  3a           DB  $3a
$5892:  3b           DB  $3b
$5893:  3c           DB  $3c
$5894:  3d           DB  $3d
$5895:  3e           DB  $3e
$5896:  3f           DB  $3f
$5897:  5f           DB  $5f
$5898:  ea           DB  $ea
$5899:  f1           DB  $f1
$589a:  ca           DB  $ca
$589b:  f0           DB  $f0
$589c:  0d           DB  $0d
$589d:  0a           DB  $0a
$589e:  61           DB  $61
$589f:  62           DB  $62
$58a0:  63           DB  $63
$58a1:  64           DB  $64
$58a2:  65           DB  $65
$58a3:  66           DB  $66
$58a4:  67           DB  $67
$58a5:  68           DB  $68
$58a6:  69           DB  $69
$58a7:  6a           DB  $6a
$58a8:  6b           DB  $6b
$58a9:  6c           DB  $6c
$58aa:  6d           DB  $6d
$58ab:  6e           DB  $6e
$58ac:  6f           DB  $6f
$58ad:  70           DB  $70
$58ae:  71           DB  $71
$58af:  72           DB  $72
$58b0:  73           DB  $73
$58b1:  74           DB  $74
$58b2:  75           DB  $75
$58b3:  76           DB  $76
$58b4:  77           DB  $77
$58b5:  78           DB  $78
$58b6:  79           DB  $79
$58b7:  7a           DB  $7a
$58b8:  7b           DB  $7b
$58b9:  7c           DB  $7c
$58ba:  7d           DB  $7d
$58bb:  7e           DB  $7e
$58bc:  60           DB  $60
$58bd:  0d           DB  $0d
$58be:  0a           DB  $0a
$58bf:  d0           DB  $d0
$58c0:  d1           DB  $d1
$58c1:  e6           DB  $e6
$58c2:  d4           DB  $d4
$58c3:  d5           DB  $d5
$58c4:  e4           DB  $e4
$58c5:  d3           DB  $d3
$58c6:  e5           DB  $e5
$58c7:  d8           DB  $d8
$58c8:  d9           DB  $d9
$58c9:  da           DB  $da
$58ca:  db           DB  $db
$58cb:  dc           DB  $dc
$58cc:  dd           DB  $dd
$58cd:  de           DB  $de
$58ce:  df           DB  $df
$58cf:  ef           DB  $ef
$58d0:  e0           DB  $e0
$58d1:  e1           DB  $e1
$58d2:  e2           DB  $e2
$58d3:  e3           DB  $e3
$58d4:  d6           DB  $d6
$58d5:  d2           DB  $d2
$58d6:  ec           DB  $ec
$58d7:  eb           DB  $eb
$58d8:  d7           DB  $d7
$58d9:  e8           DB  $e8
$58da:  ed           DB  $ed
$58db:  e9           DB  $e9
$58dc:  e7           DB  $e7
$58dd:  ee           DB  $ee
$58de:  0d           DB  $0d
$58df:  0a           DB  $0a
$58e0:  03           DB  $03
$58e1:  00           DB  $00
$58e2:  f4           DB  $f4
$58e3:  34           DB  $34
$58e4:  00           DB  $00
$58e5:  f1           DB  $f1
$58e6:  18           DB  $18
$58e7:  29           DB  $29
$58e8:  90           DB  $90
$58e9:  0b           DB  $0b
$58ea:  00           DB  $00
$58eb:  f5           DB  $f5
$58ec:  00           DB  $00
$58ed:  00           DB  $00
$58ee:  01           DB  $01
$58ef:  00           DB  $00
$58f0:  00           DB  $00
$58f1:  00           DB  $00
$58f2:  01           DB  $01
$58f3:  00           DB  $00
$58f4:  00           DB  $00
$58f5:  f6           DB  $f6
$58f6:  47           DB  $47
$58f7:  52           DB  $52
$58f8:  41           DB  $41
$58f9:  46           DB  $46
$58fa:  03           DB  $03
$58fb:  00           DB  $00
$58fc:  f8           DB  $f8
$58fd:  99           DB  $99
$58fe:  99           DB  $99
$58ff:  00           DB  $00
$5900:  00           DB  $00
$5901:  00           DB  $00
$5902:  f5           DB  $f5
$5903:  00           DB  $00
$5904:  00           DB  $00
$5905:  01           DB  $01
$5906:  00           DB  $00
$5907:  00           DB  $00
$5908:  00           DB  $00
$5909:  01           DB  $01
$590a:  00           DB  $00
$590b:  00           DB  $00
$590c:  f1           DB  $f1
$590d:  58           DB  $58
$590e:  34           DB  $34
$590f:  90           DB  $90
$5910:  0b           DB  $0b
$5911:  00           DB  $00
$5912:  f3           DB  $f3
$5913:  01           DB  $01
$5914:  00           DB  $00
$5915:  00           DB  $00
$5916:  00           DB  $00
$5917:  00           DB  $00
$5918:  f6           DB  $f6
$5919:  b3           DB  $b3
$591a:  c0           DB  $c0
$591b:  b0           DB  $b0
$591c:  c4           DB  $c4
$591d:  03           DB  $03
$591e:  00           DB  $00
$591f:  f1           DB  $f1
$5920:  b0           DB  $b0
$5921:  36           DB  $36
$5922:  00           DB  $00
$5923:  0f           DB  $0f
$5924:  00           DB  $00
$5925:  f3           DB  $f3
$5926:  55           DB  $55
$5927:  00           DB  $00
$5928:  32           DB  $32
$5929:  00           DB  $00
$592a:  00           DB  $00
$592b:  f8           DB  $f8
$592c:  cd           DB  $cd
$592d:  4c           DB  $4c
$592e:  00           DB  $00
$592f:  00           DB  $00
$5930:  00           DB  $00
$5931:  f5           DB  $f5
$5932:  66           DB  $66
$5933:  66           DB  $66
$5934:  00           DB  $00
$5935:  00           DB  $00
$5936:  51           DB  $51
$5937:  b8           DB  $b8
$5938:  00           DB  $00
$5939:  00           DB  $00
$593a:  00           DB  $00
$593b:  f6           DB  $f6
$593c:  b3           DB  $b3
$593d:  c0           DB  $c0
$593e:  b0           DB  $b0
$593f:  c4           DB  $c4
$5940:  03           DB  $03
$5941:  00           DB  $00
$5942:  f1           DB  $f1
$5943:  58           DB  $58
$5944:  34           DB  $34
$5945:  60           DB  $60
$5946:  0e           DB  $0e
$5947:  00           DB  $00
$5948:  f3           DB  $f3
$5949:  00           DB  $00
$594a:  00           DB  $00
$594b:  01           DB  $01
$594c:  00           DB  $00
$594d:  00           DB  $00
$594e:  f8           DB  $f8
$594f:  00           DB  $00
$5950:  00           DB  $00
$5951:  00           DB  $00
$5952:  00           DB  $00
$5953:  00           DB  $00
$5954:  f6           DB  $f6
$5955:  b3           DB  $b3
$5956:  c0           DB  $c0
$5957:  b0           DB  $b0
$5958:  c4           DB  $c4
$5959:  03           DB  $03
$595a:  00           DB  $00
$595b:  f1           DB  $f1
$595c:  50           DB  $50
$595d:  2d           DB  $2d
$595e:  08           DB  $08
$595f:  11           DB  $11
$5960:  00           DB  $00
$5961:  f3           DB  $f3
$5962:  55           DB  $55
$5963:  00           DB  $00
$5964:  32           DB  $32
$5965:  04           DB  $04
$5966:  00           DB  $00
$5967:  f8           DB  $f8
$5968:  cc           DB  $cc
$5969:  4c           DB  $4c
$596a:  00           DB  $00
$596b:  00           DB  $00
$596c:  00           DB  $00
$596d:  f6           DB  $f6
$596e:  47           DB  $47
$596f:  52           DB  $52
$5970:  41           DB  $41
$5971:  46           DB  $46
$5972:  03           DB  $03
$5973:  00           DB  $00
$5974:  f4           DB  $f4
$5975:  31           DB  $31
$5976:  00           DB  $00
$5977:  f1           DB  $f1
$5978:  b0           DB  $b0
$5979:  1d           DB  $1d
$597a:  68           DB  $68
$597b:  1a           DB  $1a
$597c:  00           DB  $00
$597d:  fd           DB  $fd
$597e:  01           DB  $01
$597f:  00           DB  $00
$5980:  00           DB  $00
$5981:  fa           DB  $fa
$5982:  c1           DB  $c1
$5983:  00           DB  $00
$5984:  f9           DB  $f9
$5985:  cc           DB  $cc
$5986:  01           DB  $01
$5987:  0a           DB  $0a
$5988:  00           DB  $00
$5989:  00           DB  $00
$598a:  f1           DB  $f1
$598b:  b0           DB  $b0
$598c:  1d           DB  $1d
$598d:  9c           DB  $9c
$598e:  18           DB  $18
$598f:  00           DB  $00
$5990:  f9           DB  $f9
$5991:  98           DB  $98
$5992:  03           DB  $03
$5993:  05           DB  $05
$5994:  00           DB  $00
$5995:  00           DB  $00
$5996:  f1           DB  $f1
$5997:  b0           DB  $b0
$5998:  1d           DB  $1d
$5999:  b4           DB  $b4
$599a:  14           DB  $14
$599b:  00           DB  $00
$599c:  f9           DB  $f9
$599d:  80           DB  $80
$599e:  07           DB  $07
$599f:  01           DB  $01
$59a0:  00           DB  $00
$59a1:  00           DB  $00
$59a2:  f1           DB  $f1
$59a3:  58           DB  $58
$59a4:  20           DB  $20
$59a5:  78           DB  $78
$59a6:  0f           DB  $0f
$59a7:  00           DB  $00
$59a8:  ef           DB  $ef
$59a9:  b0           DB  $b0
$59aa:  1d           DB  $1d
$59ab:  90           DB  $90
$59ac:  15           DB  $15
$59ad:  2d           DB  $2d
$59ae:  01           DB  $01
$59af:  b0           DB  $b0
$59b0:  1d           DB  $1d
$59b1:  b0           DB  $b0
$59b2:  13           DB  $13
$59b3:  58           DB  $58
$59b4:  20           DB  $20
$59b5:  78           DB  $78
$59b6:  0f           DB  $0f
$59b7:  00           DB  $00
$59b8:  f1           DB  $f1
$59b9:  b8           DB  $b8
$59ba:  1a           DB  $1a
$59bb:  88           DB  $88
$59bc:  0e           DB  $0e
$59bd:  00           DB  $00
$59be:  ef           DB  $ef
$59bf:  88           DB  $88
$59c0:  1d           DB  $1d
$59c1:  a0           DB  $a0
$59c2:  14           DB  $14
$59c3:  2d           DB  $2d
$59c4:  00           DB  $00
$59c5:  88           DB  $88
$59c6:  1d           DB  $1d
$59c7:  20           DB  $20
$59c8:  12           DB  $12
$59c9:  b8           DB  $b8
$59ca:  1a           DB  $1a
$59cb:  88           DB  $88
$59cc:  0e           DB  $0e
$59cd:  00           DB  $00
$59ce:  ee           DB  $ee
$59cf:  00           DB  $00
$59d0:  00           DB  $00
$59d1:  00           DB  $00
$59d2:  f1           DB  $f1
$59d3:  90           DB  $90
$59d4:  01           DB  $01
$59d5:  b0           DB  $b0
$59d6:  18           DB  $18
$59d7:  00           DB  $00
$59d8:  f2           DB  $f2
$59d9:  50           DB  $50
$59da:  14           DB  $14
$59db:  b0           DB  $b0
$59dc:  18           DB  $18
$59dd:  00           DB  $00
$59de:  f4           DB  $f4
$59df:  32           DB  $32
$59e0:  00           DB  $00
$59e1:  ee           DB  $ee
$59e2:  01           DB  $01
$59e3:  00           DB  $00
$59e4:  00           DB  $00
$59e5:  f1           DB  $f1
$59e6:  90           DB  $90
$59e7:  01           DB  $01
$59e8:  a8           DB  $a8
$59e9:  16           DB  $16
$59ea:  00           DB  $00
$59eb:  f2           DB  $f2
$59ec:  50           DB  $50
$59ed:  14           DB  $14
$59ee:  a8           DB  $a8
$59ef:  16           DB  $16
$59f0:  00           DB  $00
$59f1:  f4           DB  $f4
$59f2:  33           DB  $33
$59f3:  00           DB  $00
$59f4:  ee           DB  $ee
$59f5:  02           DB  $02
$59f6:  00           DB  $00
$59f7:  00           DB  $00
$59f8:  f1           DB  $f1
$59f9:  90           DB  $90
$59fa:  01           DB  $01
$59fb:  a0           DB  $a0
$59fc:  14           DB  $14
$59fd:  00           DB  $00
$59fe:  f2           DB  $f2
$59ff:  50           DB  $50
$5a00:  14           DB  $14
$5a01:  a0           DB  $a0
$5a02:  14           DB  $14
$5a03:  00           DB  $00
$5a04:  f4           DB  $f4
$5a05:  34           DB  $34
$5a06:  00           DB  $00
$5a07:  ee           DB  $ee
$5a08:  03           DB  $03
$5a09:  00           DB  $00
$5a0a:  00           DB  $00
$5a0b:  f1           DB  $f1
$5a0c:  90           DB  $90
$5a0d:  01           DB  $01
$5a0e:  98           DB  $98
$5a0f:  12           DB  $12
$5a10:  00           DB  $00
$5a11:  f2           DB  $f2
$5a12:  50           DB  $50
$5a13:  14           DB  $14
$5a14:  98           DB  $98
$5a15:  12           DB  $12
$5a16:  00           DB  $00
$5a17:  f4           DB  $f4
$5a18:  36           DB  $36
$5a19:  00           DB  $00
$5a1a:  ee           DB  $ee
$5a1b:  04           DB  $04
$5a1c:  00           DB  $00
$5a1d:  00           DB  $00
$5a1e:  f1           DB  $f1
$5a1f:  90           DB  $90
$5a20:  01           DB  $01
$5a21:  90           DB  $90
$5a22:  10           DB  $10
$5a23:  00           DB  $00
$5a24:  f2           DB  $f2
$5a25:  50           DB  $50
$5a26:  14           DB  $14
$5a27:  90           DB  $90
$5a28:  10           DB  $10
$5a29:  00           DB  $00
$5a2a:  f4           DB  $f4
$5a2b:  37           DB  $37
$5a2c:  00           DB  $00
$5a2d:  ee           DB  $ee
$5a2e:  05           DB  $05
$5a2f:  00           DB  $00
$5a30:  00           DB  $00
$5a31:  f1           DB  $f1
$5a32:  90           DB  $90
$5a33:  01           DB  $01
$5a34:  88           DB  $88
$5a35:  0e           DB  $0e
$5a36:  00           DB  $00
$5a37:  f2           DB  $f2
$5a38:  50           DB  $50
$5a39:  14           DB  $14
$5a3a:  88           DB  $88
$5a3b:  0e           DB  $0e
$5a3c:  00           DB  $00
$5a3d:  f4           DB  $f4
$5a3e:  31           DB  $31
$5a3f:  00           DB  $00
$5a40:  ee           DB  $ee
$5a41:  06           DB  $06
$5a42:  00           DB  $00
$5a43:  00           DB  $00
$5a44:  f1           DB  $f1
$5a45:  90           DB  $90
$5a46:  01           DB  $01
$5a47:  80           DB  $80
$5a48:  0c           DB  $0c
$5a49:  00           DB  $00
$5a4a:  f2           DB  $f2
$5a4b:  50           DB  $50
$5a4c:  14           DB  $14
$5a4d:  80           DB  $80
$5a4e:  0c           DB  $0c
$5a4f:  00           DB  $00
$5a50:  f1           DB  $f1
$5a51:  00           DB  $00
$5a52:  ee           DB  $ee
$5a53:  00           DB  $00
$5a54:  00           DB  $00
$5a55:  00           DB  $00
$5a56:  fd           DB  $fd
$5a57:  e8           DB  $e8
$5a58:  03           DB  $03
$5a59:  00           DB  $00
$5a5a:  fa           DB  $fa
$5a5b:  a5           DB  $a5
$5a5c:  00           DB  $00
$5a5d:  f4           DB  $f4
$5a5e:  36           DB  $36
$5a5f:  00           DB  $00
$5a60:  f1           DB  $f1
$5a61:  78           DB  $78
$5a62:  05           DB  $05
$5a63:  90           DB  $90
$5a64:  01           DB  $01
$5a65:  00           DB  $00
$5a66:  f2           DB  $f2
$5a67:  60           DB  $60
$5a68:  09           DB  $09
$5a69:  90           DB  $90
$5a6a:  01           DB  $01
$5a6b:  00           DB  $00
$5a6c:  f1           DB  $f1
$5a6d:  78           DB  $78
$5a6e:  05           DB  $05
$5a6f:  a8           DB  $a8
$5a70:  02           DB  $02
$5a71:  00           DB  $00
$5a72:  f2           DB  $f2
$5a73:  60           DB  $60
$5a74:  09           DB  $09
$5a75:  c0           DB  $c0
$5a76:  03           DB  $03
$5a77:  00           DB  $00
$5a78:  f1           DB  $f1
$5a79:  78           DB  $78
$5a7a:  05           DB  $05
$5a7b:  c0           DB  $c0
$5a7c:  03           DB  $03
$5a7d:  60           DB  $60
$5a7e:  09           DB  $09
$5a7f:  f0           DB  $f0
$5a80:  05           DB  $05
$5a81:  00           DB  $00
$5a82:  f1           DB  $f1
$5a83:  78           DB  $78
$5a84:  05           DB  $05
$5a85:  78           DB  $78
$5a86:  05           DB  $05
$5a87:  60           DB  $60
$5a88:  09           DB  $09
$5a89:  60           DB  $60
$5a8a:  09           DB  $09
$5a8b:  00           DB  $00
$5a8c:  f1           DB  $f1
$5a8d:  c0           DB  $c0
$5a8e:  03           DB  $03
$5a8f:  78           DB  $78
$5a90:  05           DB  $05
$5a91:  00           DB  $00
$5a92:  f2           DB  $f2
$5a93:  f0           DB  $f0
$5a94:  05           DB  $05
$5a95:  60           DB  $60
$5a96:  09           DB  $09
$5a97:  00           DB  $00
$5a98:  f1           DB  $f1
$5a99:  a8           DB  $a8
$5a9a:  02           DB  $02
$5a9b:  78           DB  $78
$5a9c:  05           DB  $05
$5a9d:  00           DB  $00
$5a9e:  f2           DB  $f2
$5a9f:  c0           DB  $c0
$5aa0:  03           DB  $03
$5aa1:  60           DB  $60
$5aa2:  09           DB  $09
$5aa3:  00           DB  $00
$5aa4:  f1           DB  $f1
$5aa5:  90           DB  $90
$5aa6:  01           DB  $01
$5aa7:  78           DB  $78
$5aa8:  05           DB  $05
$5aa9:  00           DB  $00
$5aaa:  f2           DB  $f2
$5aab:  90           DB  $90
$5aac:  01           DB  $01
$5aad:  60           DB  $60
$5aae:  09           DB  $09
$5aaf:  00           DB  $00
$5ab0:  f1           DB  $f1
$5ab1:  90           DB  $90
$5ab2:  01           DB  $01
$5ab3:  f0           DB  $f0
$5ab4:  28           DB  $28
$5ab5:  00           DB  $00
$5ab6:  f2           DB  $f2
$5ab7:  90           DB  $90
$5ab8:  01           DB  $01
$5ab9:  08           DB  $08
$5aba:  25           DB  $25
$5abb:  00           DB  $00
$5abc:  f1           DB  $f1
$5abd:  a8           DB  $a8
$5abe:  02           DB  $02
$5abf:  f0           DB  $f0
$5ac0:  28           DB  $28
$5ac1:  00           DB  $00
$5ac2:  f2           DB  $f2
$5ac3:  c0           DB  $c0
$5ac4:  03           DB  $03
$5ac5:  08           DB  $08
$5ac6:  25           DB  $25
$5ac7:  00           DB  $00
$5ac8:  f1           DB  $f1
$5ac9:  c0           DB  $c0
$5aca:  03           DB  $03
$5acb:  f0           DB  $f0
$5acc:  28           DB  $28
$5acd:  00           DB  $00
$5ace:  f2           DB  $f2
$5acf:  f0           DB  $f0
$5ad0:  05           DB  $05
$5ad1:  08           DB  $08
$5ad2:  25           DB  $25
$5ad3:  00           DB  $00
$5ad4:  f1           DB  $f1
$5ad5:  78           DB  $78
$5ad6:  05           DB  $05
$5ad7:  f0           DB  $f0
$5ad8:  28           DB  $28
$5ad9:  00           DB  $00
$5ada:  f2           DB  $f2
$5adb:  60           DB  $60
$5adc:  09           DB  $09
$5add:  08           DB  $08
$5ade:  25           DB  $25
$5adf:  00           DB  $00
$5ae0:  f1           DB  $f1
$5ae1:  78           DB  $78
$5ae2:  05           DB  $05
$5ae3:  a8           DB  $a8
$5ae4:  2a           DB  $2a
$5ae5:  00           DB  $00
$5ae6:  f2           DB  $f2
$5ae7:  60           DB  $60
$5ae8:  09           DB  $09
$5ae9:  78           DB  $78
$5aea:  28           DB  $28
$5aeb:  00           DB  $00
$5aec:  f1           DB  $f1
$5aed:  78           DB  $78
$5aee:  05           DB  $05
$5aef:  c0           DB  $c0
$5af0:  2b           DB  $2b
$5af1:  00           DB  $00
$5af2:  f2           DB  $f2
$5af3:  60           DB  $60
$5af4:  09           DB  $09
$5af5:  a8           DB  $a8
$5af6:  2a           DB  $2a
$5af7:  00           DB  $00
$5af8:  f1           DB  $f1
$5af9:  78           DB  $78
$5afa:  05           DB  $05
$5afb:  d8           DB  $d8
$5afc:  2c           DB  $2c
$5afd:  00           DB  $00
$5afe:  f2           DB  $f2
$5aff:  60           DB  $60
$5b00:  09           DB  $09
$5b01:  d8           DB  $d8
$5b02:  2c           DB  $2c
$5b03:  00           DB  $00
$5b04:  f1           DB  $f1
$5b05:  10           DB  $10
$5b06:  40           DB  $40
$5b07:  f0           DB  $f0
$5b08:  28           DB  $28
$5b09:  00           DB  $00
$5b0a:  f2           DB  $f2
$5b0b:  10           DB  $10
$5b0c:  40           DB  $40
$5b0d:  08           DB  $08
$5b0e:  25           DB  $25
$5b0f:  00           DB  $00
$5b10:  f1           DB  $f1
$5b11:  f8           DB  $f8
$5b12:  3e           DB  $3e
$5b13:  f0           DB  $f0
$5b14:  28           DB  $28
$5b15:  00           DB  $00
$5b16:  f2           DB  $f2
$5b17:  e0           DB  $e0
$5b18:  3d           DB  $3d
$5b19:  08           DB  $08
$5b1a:  25           DB  $25
$5b1b:  00           DB  $00
$5b1c:  f1           DB  $f1
$5b1d:  e0           DB  $e0
$5b1e:  3d           DB  $3d
$5b1f:  f0           DB  $f0
$5b20:  28           DB  $28
$5b21:  00           DB  $00
$5b22:  f2           DB  $f2
$5b23:  b0           DB  $b0
$5b24:  3b           DB  $3b
$5b25:  08           DB  $08
$5b26:  25           DB  $25
$5b27:  00           DB  $00
$5b28:  f1           DB  $f1
$5b29:  28           DB  $28
$5b2a:  3c           DB  $3c
$5b2b:  f0           DB  $f0
$5b2c:  28           DB  $28
$5b2d:  00           DB  $00
$5b2e:  f2           DB  $f2
$5b2f:  40           DB  $40
$5b30:  38           DB  $38
$5b31:  08           DB  $08
$5b32:  25           DB  $25
$5b33:  00           DB  $00
$5b34:  f1           DB  $f1
$5b35:  28           DB  $28
$5b36:  3c           DB  $3c
$5b37:  80           DB  $80
$5b38:  2a           DB  $2a
$5b39:  00           DB  $00
$5b3a:  f2           DB  $f2
$5b3b:  40           DB  $40
$5b3c:  38           DB  $38
$5b3d:  28           DB  $28
$5b3e:  28           DB  $28
$5b3f:  00           DB  $00
$5b40:  f1           DB  $f1
$5b41:  28           DB  $28
$5b42:  3c           DB  $3c
$5b43:  c0           DB  $c0
$5b44:  2b           DB  $2b
$5b45:  00           DB  $00
$5b46:  f2           DB  $f2
$5b47:  40           DB  $40
$5b48:  38           DB  $38
$5b49:  a8           DB  $a8
$5b4a:  2a           DB  $2a
$5b4b:  00           DB  $00
$5b4c:  f1           DB  $f1
$5b4d:  28           DB  $28
$5b4e:  3c           DB  $3c
$5b4f:  d8           DB  $d8
$5b50:  2c           DB  $2c
$5b51:  00           DB  $00
$5b52:  f2           DB  $f2
$5b53:  40           DB  $40
$5b54:  38           DB  $38
$5b55:  d8           DB  $d8
$5b56:  2c           DB  $2c
$5b57:  00           DB  $00
$5b58:  f1           DB  $f1
$5b59:  28           DB  $28
$5b5a:  3c           DB  $3c
$5b5b:  90           DB  $90
$5b5c:  01           DB  $01
$5b5d:  00           DB  $00
$5b5e:  f2           DB  $f2
$5b5f:  40           DB  $40
$5b60:  38           DB  $38
$5b61:  90           DB  $90
$5b62:  01           DB  $01
$5b63:  00           DB  $00
$5b64:  f1           DB  $f1
$5b65:  28           DB  $28
$5b66:  3c           DB  $3c
$5b67:  a8           DB  $a8
$5b68:  02           DB  $02
$5b69:  00           DB  $00
$5b6a:  f2           DB  $f2
$5b6b:  40           DB  $40
$5b6c:  38           DB  $38
$5b6d:  c0           DB  $c0
$5b6e:  03           DB  $03
$5b6f:  00           DB  $00
$5b70:  f1           DB  $f1
$5b71:  28           DB  $28
$5b72:  3c           DB  $3c
$5b73:  c0           DB  $c0
$5b74:  03           DB  $03
$5b75:  00           DB  $00
$5b76:  f2           DB  $f2
$5b77:  40           DB  $40
$5b78:  38           DB  $38
$5b79:  f0           DB  $f0
$5b7a:  05           DB  $05
$5b7b:  00           DB  $00
$5b7c:  f1           DB  $f1
$5b7d:  28           DB  $28
$5b7e:  3c           DB  $3c
$5b7f:  78           DB  $78
$5b80:  05           DB  $05
$5b81:  00           DB  $00
$5b82:  f2           DB  $f2
$5b83:  40           DB  $40
$5b84:  38           DB  $38
$5b85:  60           DB  $60
$5b86:  09           DB  $09
$5b87:  00           DB  $00
$5b88:  f1           DB  $f1
$5b89:  e0           DB  $e0
$5b8a:  3d           DB  $3d
$5b8b:  78           DB  $78
$5b8c:  05           DB  $05
$5b8d:  00           DB  $00
$5b8e:  f2           DB  $f2
$5b8f:  b0           DB  $b0
$5b90:  3b           DB  $3b
$5b91:  60           DB  $60
$5b92:  09           DB  $09
$5b93:  00           DB  $00
$5b94:  f1           DB  $f1
$5b95:  f8           DB  $f8
$5b96:  3e           DB  $3e
$5b97:  78           DB  $78
$5b98:  05           DB  $05
$5b99:  00           DB  $00
$5b9a:  f2           DB  $f2
$5b9b:  e0           DB  $e0
$5b9c:  3d           DB  $3d
$5b9d:  60           DB  $60
$5b9e:  09           DB  $09
$5b9f:  00           DB  $00
$5ba0:  f1           DB  $f1
$5ba1:  10           DB  $10
$5ba2:  40           DB  $40
$5ba3:  78           DB  $78
$5ba4:  05           DB  $05
$5ba5:  00           DB  $00
$5ba6:  f2           DB  $f2
$5ba7:  10           DB  $10
$5ba8:  40           DB  $40
$5ba9:  60           DB  $60
$5baa:  09           DB  $09
$5bab:  00           DB  $00
$5bac:  f1           DB  $f1
$5bad:  00           DB  $00
$5bae:  00           DB  $00
$5baf:  00           DB  $00
$5bb0:  00           DB  $00
$5bb1:  00           DB  $00
$5bb2:  f0           DB  $f0
$5bb3:  00           DB  $00
$5bb4:  fc           DB  $fc
$5bb5:  00           DB  $00
$5bb6:  ff           DB  $ff
$5bb7:  ff           DB  $ff
$5bb8:  00           DB  $00
$5bb9:  00           DB  $00
$5bba:  ff           DB  $ff
$5bbb:  62           DB  $62
$5bbc:  01           DB  $01
$5bbd:  15           DB  $15
$5bbe:  00           DB  $00
$5bbf:  cd           DB  $cd
$5bc0:  bf           DB  $bf
$5bc1:  3f           DB  $3f
$5bc2:  01           DB  $01
$5bc3:  90           DB  $90
$5bc4:  01           DB  $01
$5bc5:  cd           DB  $cd
$5bc6:  38           DB  $38
$5bc7:  28           DB  $28
$5bc8:  22           DB  $22
$5bc9:  c8           DB  $c8
$5bca:  62           DB  $62
$5bcb:  eb           DB  $eb
$5bcc:  22           DB  $22
$5bcd:  ca           DB  $ca
$5bce:  62           DB  $62
$5bcf:  21           DB  $21
$5bd0:  ec           DB  $ec
$5bd1:  62           DB  $62
$5bd2:  3e           DB  $3e
$5bd3:  02           DB  $02
$5bd4:  b6           DB  $b6
$5bd5:  77           DB  $77
$5bd6:  c9           DB  $c9
$5bd7:  21           DB  $21
$5bd8:  88           DB  $88
$5bd9:  62           DB  $62
$5bda:  11           DB  $11
$5bdb:  88           DB  $88
$5bdc:  62           DB  $62
$5bdd:  cd           DB  $cd
$5bde:  31           DB  $31
$5bdf:  2c           DB  $2c
$5be0:  21           DB  $21
$5be1:  8c           DB  $8c
$5be2:  62           DB  $62
$5be3:  11           DB  $11
$5be4:  8c           DB  $8c
$5be5:  62           DB  $62
$5be6:  cd           DB  $cd
$5be7:  31           DB  $31
$5be8:  2c           DB  $2c
$5be9:  cd           DB  $cd
$5bea:  5f           DB  $5f
$5beb:  44           DB  $44
$5bec:  c3           DB  $c3
$5bed:  be           DB  $be
$5bee:  43           DB  $43
$5bef:  7a           DB  $7a
$5bf0:  e6           DB  $e6
$5bf1:  80           DB  $80
$5bf2:  f5           DB  $f5
$5bf3:  7c           DB  $7c
$5bf4:  e6           DB  $e6
$5bf5:  80           DB  $80
$5bf6:  f5           DB  $f5
$5bf7:  3e           DB  $3e
$5bf8:  7f           DB  $7f
$5bf9:  a4           DB  $a4
$5bfa:  67           DB  $67
$5bfb:  b5           DB  $b5
$5bfc:  ca           DB  $ca
$5bfd:  ed           DB  $ed
$5bfe:  43           DB  $43
$5bff:  3e           DB  $3e
$5c00:  7f           DB  $7f
$5c01:  a2           DB  $a2
$5c02:  57           DB  $57
$5c03:  b3           DB  $b3
$5c04:  ca           DB  $ca
$5c05:  02           DB  $02
$5c06:  44           DB  $44
$5c07:  7c           DB  $7c
$5c08:  ba           DB  $ba
$5c09:  ca           DB  $ca
$5c0a:  9a           DB  $9a
$5c0b:  43           DB  $43
$5c0c:  d2           DB  $d2
$5c0d:  d9           DB  $d9
$5c0e:  43           DB  $43
$5c0f:  c3           DB  $c3
$5c10:  a2           DB  $a2
$5c11:  43           DB  $43
$5c12:  7d           DB  $7d
$5c13:  bb           DB  $bb
$5c14:  ca           DB  $ca
$5c15:  e8           DB  $e8
$5c16:  43           DB  $43
$5c17:  d2           DB  $d2
$5c18:  d9           DB  $d9
$5c19:  43           DB  $43
$5c1a:  cd           DB  $cd
$5c1b:  27           DB  $27
$5c1c:  29           DB  $29
$5c1d:  eb           DB  $eb
$5c1e:  cd           DB  $cd
$5c1f:  11           DB  $11
$5c20:  40           DB  $40
$5c21:  cd           DB  $cd
$5c22:  2c           DB  $2c
$5c23:  40           DB  $40
$5c24:  af           DB  $af
$5c25:  32           DB  $32
$5c26:  a5           DB  $a5
$5c27:  61           DB  $61
$5c28:  32           DB  $32
$5c29:  a9           DB  $a9
$5c2a:  61           DB  $61
$5c2b:  f1           DB  $f1
$5c2c:  21           DB  $21
$5c2d:  a6           DB  $a6
$5c2e:  61           DB  $61
$5c2f:  77           DB  $77
$5c30:  f1           DB  $f1
$5c31:  21           DB  $21
$5c32:  aa           DB  $aa
$5c33:  61           DB  $61
$5c34:  77           DB  $77
$5c35:  c9           DB  $c9
$5c36:  21           DB  $21
$5c37:  a3           DB  $a3
$5c38:  61           DB  $61
$5c39:  11           DB  $11
$5c3a:  d4           DB  $d4
$5c3b:  62           DB  $62
$5c3c:  cd           DB  $cd
$5c3d:  31           DB  $31
$5c3e:  2c           DB  $2c
$5c3f:  21           DB  $21
$5c40:  a7           DB  $a7
$5c41:  61           DB  $61
$5c42:  11           DB  $11
$5c43:  d8           DB  $d8
$5c44:  62           DB  $62
$5c45:  cd           DB  $cd
$5c46:  31           DB  $31
$5c47:  2c           DB  $2c
$5c48:  c9           DB  $c9
$5c49:  21           DB  $21
$5c4a:  ec           DB  $ec
$5c4b:  62           DB  $62
$5c4c:  3e           DB  $3e
$5c4d:  02           DB  $02
$5c4e:  b6           DB  $b6
$5c4f:  77           DB  $77
$5c50:  c9           DB  $c9
$5c51:  eb           DB  $eb
$5c52:  cd           DB  $cd
$5c53:  27           DB  $27
$5c54:  29           DB  $29
$5c55:  eb           DB  $eb
$5c56:  cd           DB  $cd
$5c57:  11           DB  $11
$5c58:  40           DB  $40
$5c59:  3e           DB  $3e
$5c5a:  5a           DB  $5a
$5c5b:  90           DB  $90
$5c5c:  47           DB  $47
$5c5d:  c3           DB  $c3
$5c5e:  a9           DB  $a9
$5c5f:  43           DB  $43
$5c60:  06           DB  $06
$5c61:  2d           DB  $2d
$5c62:  c3           DB  $c3
$5c63:  a9           DB  $a9
$5c64:  43           DB  $43
$5c65:  21           DB  $21
$5c66:  01           DB  $01
$5c67:  00           DB  $00
$5c68:  22           DB  $22
$5c69:  a9           DB  $a9
$5c6a:  61           DB  $61
$5c6b:  21           DB  $21
$5c6c:  00           DB  $00
$5c6d:  00           DB  $00
$5c6e:  22           DB  $22
$5c6f:  a5           DB  $a5
$5c70:  61           DB  $61
$5c71:  22           DB  $22
$5c72:  a7           DB  $a7
$5c73:  61           DB  $61
$5c74:  22           DB  $22
$5c75:  a3           DB  $a3
$5c76:  61           DB  $61
$5c77:  c3           DB  $c3
$5c78:  b3           DB  $b3
$5c79:  43           DB  $43
$5c7a:  21           DB  $21
$5c7b:  01           DB  $01
$5c7c:  00           DB  $00
$5c7d:  22           DB  $22
$5c7e:  a5           DB  $a5
$5c7f:  61           DB  $61
$5c80:  21           DB  $21
$5c81:  00           DB  $00
$5c82:  00           DB  $00
$5c83:  22           DB  $22
$5c84:  a3           DB  $a3
$5c85:  61           DB  $61
$5c86:  22           DB  $22
$5c87:  a9           DB  $a9
$5c88:  61           DB  $61
$5c89:  22           DB  $22
$5c8a:  a7           DB  $a7
$5c8b:  61           DB  $61
$5c8c:  c3           DB  $c3
$5c8d:  b3           DB  $b3
$5c8e:  43           DB  $43
$5c8f:  3a           DB  $3a
$5c90:  39           DB  $39
$5c91:  63           DB  $63
$5c92:  21           DB  $21
$5c93:  76           DB  $76
$5c94:  48           DB  $48
$5c95:  cd           DB  $cd
$5c96:  84           DB  $84
$5c97:  40           DB  $40
$5c98:  d5           DB  $d5
$5c99:  2a           DB  $2a
$5c9a:  8a           DB  $8a
$5c9b:  62           DB  $62
$5c9c:  eb           DB  $eb
$5c9d:  2a           DB  $2a
$5c9e:  88           DB  $88
$5c9f:  62           DB  $62
$5ca0:  c1           DB  $c1
$5ca1:  cd           DB  $cd
$5ca2:  38           DB  $38
$5ca3:  28           DB  $28
$5ca4:  22           DB  $22
$5ca5:  88           DB  $88
$5ca6:  62           DB  $62
$5ca7:  eb           DB  $eb
$5ca8:  22           DB  $22
$5ca9:  8a           DB  $8a
$5caa:  62           DB  $62
$5cab:  3a           DB  $3a
$5cac:  39           DB  $39
$5cad:  63           DB  $63
$5cae:  21           DB  $21
$5caf:  6c           DB  $6c
$5cb0:  48           DB  $48
$5cb1:  cd           DB  $cd
$5cb2:  84           DB  $84
$5cb3:  40           DB  $40
$5cb4:  d5           DB  $d5
$5cb5:  2a           DB  $2a
$5cb6:  8e           DB  $8e
$5cb7:  62           DB  $62
$5cb8:  eb           DB  $eb
$5cb9:  2a           DB  $2a
$5cba:  8c           DB  $8c
$5cbb:  62           DB  $62
$5cbc:  c1           DB  $c1
$5cbd:  cd           DB  $cd
$5cbe:  38           DB  $38
$5cbf:  28           DB  $28
$5cc0:  22           DB  $22
$5cc1:  8c           DB  $8c
$5cc2:  62           DB  $62
$5cc3:  eb           DB  $eb
$5cc4:  22           DB  $22
$5cc5:  8e           DB  $8e
$5cc6:  62           DB  $62
$5cc7:  cd           DB  $cd
$5cc8:  5f           DB  $5f
$5cc9:  44           DB  $44
$5cca:  c3           DB  $c3
$5ccb:  be           DB  $be
$5ccc:  43           DB  $43
$5ccd:  06           DB  $06
$5cce:  04           DB  $04
$5ccf:  be           DB  $be
$5cd0:  c0           DB  $c0
$5cd1:  23           DB  $23
$5cd2:  05           DB  $05
$5cd3:  c2           DB  $c2
$5cd4:  57           DB  $57
$5cd5:  44           DB  $44
$5cd6:  c9           DB  $c9
$5cd7:  cd           DB  $cd
$5cd8:  be           DB  $be
$5cd9:  43           DB  $43
$5cda:  cd           DB  $cd
$5cdb:  d1           DB  $d1
$5cdc:  43           DB  $43
$5cdd:  2a           DB  $2a
$5cde:  8a           DB  $8a
$5cdf:  62           DB  $62
$5ce0:  7c           DB  $7c
$5ce1:  e6           DB  $e6
$5ce2:  80           DB  $80
$5ce3:  f5           DB  $f5
$5ce4:  7c           DB  $7c
$5ce5:  e6           DB  $e6
$5ce6:  7f           DB  $7f
$5ce7:  67           DB  $67
$5ce8:  22           DB  $22
$5ce9:  8a           DB  $8a
$5cea:  62           DB  $62
$5ceb:  2a           DB  $2a
$5cec:  8e           DB  $8e
$5ced:  62           DB  $62
$5cee:  7c           DB  $7c
$5cef:  e6           DB  $e6
$5cf0:  80           DB  $80
$5cf1:  f5           DB  $f5
$5cf2:  7c           DB  $7c
$5cf3:  e6           DB  $e6
$5cf4:  7f           DB  $7f
$5cf5:  67           DB  $67
$5cf6:  22           DB  $22
$5cf7:  8e           DB  $8e
$5cf8:  62           DB  $62
$5cf9:  af           DB  $af
$5cfa:  21           DB  $21
$5cfb:  88           DB  $88
$5cfc:  62           DB  $62
$5cfd:  cd           DB  $cd
$5cfe:  55           DB  $55
$5cff:  44           DB  $44
$5d00:  ca           DB  $ca
$5d01:  02           DB  $02
$5d02:  44           DB  $44
$5d03:  21           DB  $21
$5d04:  8c           DB  $8c
$5d05:  62           DB  $62
$5d06:  cd           DB  $cd
$5d07:  55           DB  $55
$5d08:  44           DB  $44
$5d09:  ca           DB  $ca
$5d0a:  ed           DB  $ed
$5d0b:  43           DB  $43
$5d0c:  21           DB  $21
$5d0d:  88           DB  $88
$5d0e:  62           DB  $62
$5d0f:  11           DB  $11
$5d10:  8c           DB  $8c
$5d11:  62           DB  $62
$5d12:  cd           DB  $cd
$5d13:  e6           DB  $e6
$5d14:  2b           DB  $2b
$5d15:  ca           DB  $ca
$5d16:  e8           DB  $e8
$5d17:  43           DB  $43
$5d18:  f5           DB  $f5
$5d19:  21           DB  $21
$5d1a:  88           DB  $88
$5d1b:  62           DB  $62
$5d1c:  11           DB  $11
$5d1d:  8c           DB  $8c
$5d1e:  62           DB  $62
$5d1f:  da           DB  $da
$5d20:  ab           DB  $ab
$5d21:  44           DB  $44
$5d22:  eb           DB  $eb
$5d23:  cd           DB  $cd
$5d24:  f1           DB  $f1
$5d25:  29           DB  $29
$5d26:  cd           DB  $cd
$5d27:  11           DB  $11
$5d28:  40           DB  $40
$5d29:  f1           DB  $f1
$5d2a:  da           DB  $da
$5d2b:  a9           DB  $a9
$5d2c:  43           DB  $43
$5d2d:  3e           DB  $3e
$5d2e:  5a           DB  $5a
$5d2f:  90           DB  $90
$5d30:  47           DB  $47
$5d31:  c3           DB  $c3
$5d32:  a9           DB  $a9
$5d33:  43           DB  $43
$5d34:  3a           DB  $3a
$5d35:  90           DB  $90
$5d36:  62           DB  $62
$5d37:  fe           DB  $fe
$5d38:  06           DB  $06
$5d39:  da           DB  $da
$5d3a:  c6           DB  $c6
$5d3b:  44           DB  $44
$5d3c:  3e           DB  $3e
$5d3d:  00           DB  $00
$5d3e:  cd           DB  $cd
$5d3f:  83           DB  $83
$5d40:  3e           DB  $3e
$5d41:  22           DB  $22
$5d42:  9a           DB  $9a
$5d43:  62           DB  $62
$5d44:  c9           DB  $c9
$5d45:  3a           DB  $3a
$5d46:  91           DB  $91
$5d47:  62           DB  $62
$5d48:  fe           DB  $fe
$5d49:  06           DB  $06
$5d4a:  da           DB  $da
$5d4b:  d7           DB  $d7
$5d4c:  44           DB  $44
$5d4d:  3e           DB  $3e
$5d4e:  01           DB  $01
$5d4f:  cd           DB  $cd
$5d50:  83           DB  $83
$5d51:  3e           DB  $3e
$5d52:  22           DB  $22
$5d53:  98           DB  $98
$5d54:  62           DB  $62
$5d55:  c9           DB  $c9
$5d56:  2a           DB  $2a
$5d57:  98           DB  $98
$5d58:  62           DB  $62
$5d59:  22           DB  $22
$5d5a:  96           DB  $96
$5d5b:  62           DB  $62
$5d5c:  c9           DB  $c9
$5d5d:  2a           DB  $2a
$5d5e:  9a           DB  $9a
$5d5f:  62           DB  $62
$5d60:  22           DB  $22
$5d61:  96           DB  $96
$5d62:  62           DB  $62
$5d63:  c9           DB  $c9
$5d64:  08           DB  $08
$5d65:  61           DB  $61
$5d66:  00           DB  $00
$5d67:  00           DB  $00
$5d68:  00           DB  $00
$5d69:  80           DB  $80
$5d6a:  00           DB  $00
$5d6b:  00           DB  $00
$5d6c:  8c           DB  $8c
$5d6d:  00           DB  $00
$5d6e:  99           DB  $99
$5d6f:  00           DB  $00
$5d70:  00           DB  $00
$5d71:  88           DB  $88
$5d72:  8c           DB  $8c
$5d73:  88           DB  $88
$5d74:  99           DB  $99
$5d75:  88           DB  $88
$5d76:  00           DB  $00
$5d77:  90           DB  $90
$5d78:  8c           DB  $8c
$5d79:  90           DB  $90
$5d7a:  99           DB  $99
$5d7b:  90           DB  $90
$5d7c:  00           DB  $00
$5d7d:  00           DB  $00
$5d7e:  0c           DB  $0c
$5d7f:  08           DB  $08
$5d80:  8c           DB  $8c
$5d81:  08           DB  $08
$5d82:  a5           DB  $a5
$5d83:  08           DB  $08
$5d84:  0c           DB  $0c
$5d85:  88           DB  $88
$5d86:  8c           DB  $8c
$5d87:  88           DB  $88
$5d88:  a5           DB  $a5
$5d89:  88           DB  $88
$5d8a:  0c           DB  $0c
$5d8b:  98           DB  $98
$5d8c:  8c           DB  $8c
$5d8d:  98           DB  $98
$5d8e:  a5           DB  $a5
$5d8f:  98           DB  $98
$5d90:  4c           DB  $4c
$5d91:  46           DB  $46
$5d92:  ac           DB  $ac
$5d93:  46           DB  $46
$5d94:  0c           DB  $0c
$5d95:  47           DB  $47
$5d96:  ec           DB  $ec
$5d97:  47           DB  $47
$5d98:  4c           DB  $4c
$5d99:  46           DB  $46
$5d9a:  ac           DB  $ac
$5d9b:  46           DB  $46
$5d9c:  11           DB  $11
$5d9d:  49           DB  $49
$5d9e:  14           DB  $14
$5d9f:  49           DB  $49
$5da0:  27           DB  $27
$5da1:  49           DB  $49
$5da2:  3c           DB  $3c
$5da3:  49           DB  $49
$5da4:  55           DB  $55
$5da5:  49           DB  $49
$5da6:  8a           DB  $8a
$5da7:  49           DB  $49
$5da8:  c9           DB  $c9
$5da9:  49           DB  $49
$5daa:  f2           DB  $f2
$5dab:  49           DB  $49
$5dac:  fd           DB  $fd
$5dad:  49           DB  $49
$5dae:  0c           DB  $0c
$5daf:  4a           DB  $4a
$5db0:  1b           DB  $1b
$5db1:  4a           DB  $4a
$5db2:  2e           DB  $2e
$5db3:  4a           DB  $4a
$5db4:  3b           DB  $3b
$5db5:  4a           DB  $4a
$5db6:  4e           DB  $4e
$5db7:  4a           DB  $4a
$5db8:  55           DB  $55
$5db9:  4a           DB  $4a
$5dba:  62           DB  $62
$5dbb:  4a           DB  $4a
$5dbc:  69           DB  $69
$5dbd:  4a           DB  $4a
$5dbe:  86           DB  $86
$5dbf:  4a           DB  $4a
$5dc0:  8f           DB  $8f
$5dc1:  4a           DB  $4a
$5dc2:  a4           DB  $a4
$5dc3:  4a           DB  $4a
$5dc4:  bb           DB  $bb
$5dc5:  4a           DB  $4a
$5dc6:  ca           DB  $ca
$5dc7:  4a           DB  $4a
$5dc8:  e1           DB  $e1
$5dc9:  4a           DB  $4a
$5dca:  04           DB  $04
$5dcb:  4b           DB  $4b
$5dcc:  0f           DB  $0f
$5dcd:  4b           DB  $4b
$5dce:  42           DB  $42
$5dcf:  4b           DB  $4b
$5dd0:  65           DB  $65
$5dd1:  4b           DB  $4b
$5dd2:  7e           DB  $7e
$5dd3:  4b           DB  $4b
$5dd4:  9d           DB  $9d
$5dd5:  4b           DB  $4b
$5dd6:  a6           DB  $a6
$5dd7:  4b           DB  $4b
$5dd8:  b3           DB  $b3
$5dd9:  4b           DB  $4b
$5dda:  bc           DB  $bc
$5ddb:  4b           DB  $4b
$5ddc:  a8           DB  $a8
$5ddd:  51           DB  $51
$5dde:  22           DB  $22
$5ddf:  4f           DB  $4f
$5de0:  e1           DB  $e1
$5de1:  51           DB  $51
$5de2:  06           DB  $06
$5de3:  52           DB  $52
$5de4:  19           DB  $19
$5de5:  52           DB  $52
$5de6:  2e           DB  $2e
$5de7:  52           DB  $52
$5de8:  3f           DB  $3f
$5de9:  52           DB  $52
$5dea:  4e           DB  $4e
$5deb:  52           DB  $52
$5dec:  65           DB  $65
$5ded:  52           DB  $52
$5dee:  78           DB  $78
$5def:  52           DB  $52
$5df0:  7f           DB  $7f
$5df1:  52           DB  $52
$5df2:  8c           DB  $8c
$5df3:  52           DB  $52
$5df4:  9f           DB  $9f
$5df5:  52           DB  $52
$5df6:  a8           DB  $a8
$5df7:  52           DB  $52
$5df8:  b5           DB  $b5
$5df9:  52           DB  $52
$5dfa:  c0           DB  $c0
$5dfb:  52           DB  $52
$5dfc:  dd           DB  $dd
$5dfd:  52           DB  $52
$5dfe:  f2           DB  $f2
$5dff:  52           DB  $52
$5e00:  15           DB  $15
$5e01:  53           DB  $53
$5e02:  30           DB  $30
$5e03:  53           DB  $53
$5e04:  4b           DB  $4b
$5e05:  53           DB  $53
$5e06:  58           DB  $58
$5e07:  53           DB  $53
$5e08:  6b           DB  $6b
$5e09:  53           DB  $53
$5e0a:  74           DB  $74
$5e0b:  53           DB  $53
$5e0c:  81           DB  $81
$5e0d:  53           DB  $53
$5e0e:  8e           DB  $8e
$5e0f:  53           DB  $53
$5e10:  9d           DB  $9d
$5e11:  53           DB  $53
$5e12:  a8           DB  $a8
$5e13:  53           DB  $53
$5e14:  b3           DB  $b3
$5e15:  53           DB  $53
$5e16:  ba           DB  $ba
$5e17:  53           DB  $53
$5e18:  c5           DB  $c5
$5e19:  53           DB  $53
$5e1a:  ce           DB  $ce
$5e1b:  53           DB  $53
$5e1c:  d5           DB  $d5
$5e1d:  53           DB  $53
$5e1e:  0a           DB  $0a
$5e1f:  4c           DB  $4c
$5e20:  e0           DB  $e0
$5e21:  53           DB  $53
$5e22:  f5           DB  $f5
$5e23:  53           DB  $53
$5e24:  08           DB  $08
$5e25:  54           DB  $54
$5e26:  1d           DB  $1d
$5e27:  54           DB  $54
$5e28:  38           DB  $38
$5e29:  54           DB  $54
$5e2a:  4b           DB  $4b
$5e2b:  54           DB  $54
$5e2c:  68           DB  $68
$5e2d:  54           DB  $54
$5e2e:  7b           DB  $7b
$5e2f:  54           DB  $54
$5e30:  86           DB  $86
$5e31:  54           DB  $54
$5e32:  9f           DB  $9f
$5e33:  54           DB  $54
$5e34:  b2           DB  $b2
$5e35:  54           DB  $54
$5e36:  bf           DB  $bf
$5e37:  54           DB  $54
$5e38:  d4           DB  $d4
$5e39:  54           DB  $54
$5e3a:  f8           DB  $f8
$5e3b:  54           DB  $54
$5e3c:  e3           DB  $e3
$5e3d:  54           DB  $54
$5e3e:  15           DB  $15
$5e3f:  55           DB  $55
$5e40:  2a           DB  $2a
$5e41:  55           DB  $55
$5e42:  37           DB  $37
$5e43:  55           DB  $55
$5e44:  54           DB  $54
$5e45:  55           DB  $55
$5e46:  61           DB  $61
$5e47:  55           DB  $55
$5e48:  70           DB  $70
$5e49:  55           DB  $55
$5e4a:  79           DB  $79
$5e4b:  55           DB  $55
$5e4c:  86           DB  $86
$5e4d:  55           DB  $55
$5e4e:  93           DB  $93
$5e4f:  55           DB  $55
$5e50:  a4           DB  $a4
$5e51:  55           DB  $55
$5e52:  af           DB  $af
$5e53:  55           DB  $55
$5e54:  c8           DB  $c8
$5e55:  55           DB  $55
$5e56:  cf           DB  $cf
$5e57:  55           DB  $55
$5e58:  e8           DB  $e8
$5e59:  55           DB  $55
$5e5a:  94           DB  $94
$5e5b:  48           DB  $48
$5e5c:  e3           DB  $e3
$5e5d:  4b           DB  $4b
$5e5e:  0a           DB  $0a
$5e5f:  4c           DB  $4c
$5e60:  25           DB  $25
$5e61:  4c           DB  $4c
$5e62:  42           DB  $42
$5e63:  4c           DB  $4c
$5e64:  57           DB  $57
$5e65:  4c           DB  $4c
$5e66:  76           DB  $76
$5e67:  4c           DB  $4c
$5e68:  91           DB  $91
$5e69:  4c           DB  $4c
$5e6a:  b4           DB  $b4
$5e6b:  4c           DB  $4c
$5e6c:  d3           DB  $d3
$5e6d:  4c           DB  $4c
$5e6e:  e0           DB  $e0
$5e6f:  4c           DB  $4c
$5e70:  ef           DB  $ef
$5e71:  4c           DB  $4c
$5e72:  04           DB  $04
$5e73:  4d           DB  $4d
$5e74:  17           DB  $17
$5e75:  4d           DB  $4d
$5e76:  22           DB  $22
$5e77:  4d           DB  $4d
$5e78:  2f           DB  $2f
$5e79:  4d           DB  $4d
$5e7a:  42           DB  $42
$5e7b:  4d           DB  $4d
$5e7c:  5f           DB  $5f
$5e7d:  4d           DB  $4d
$5e7e:  6e           DB  $6e
$5e7f:  4d           DB  $4d
$5e80:  8d           DB  $8d
$5e81:  4d           DB  $4d
$5e82:  a6           DB  $a6
$5e83:  4d           DB  $4d
$5e84:  b9           DB  $b9
$5e85:  4d           DB  $4d
$5e86:  ce           DB  $ce
$5e87:  4d           DB  $4d
$5e88:  e7           DB  $e7
$5e89:  4d           DB  $4d
$5e8a:  04           DB  $04
$5e8b:  4e           DB  $4e
$5e8c:  2d           DB  $2d
$5e8d:  4e           DB  $4e
$5e8e:  46           DB  $46
$5e8f:  4e           DB  $4e
$5e90:  61           DB  $61
$5e91:  4e           DB  $4e
$5e92:  88           DB  $88
$5e93:  4e           DB  $4e
$5e94:  9d           DB  $9d
$5e95:  4e           DB  $4e
$5e96:  b6           DB  $b6
$5e97:  4e           DB  $4e
$5e98:  d1           DB  $d1
$5e99:  4e           DB  $4e
$5e9a:  e4           DB  $e4
$5e9b:  4e           DB  $4e
$5e9c:  fb           DB  $fb
$5e9d:  4e           DB  $4e
$5e9e:  22           DB  $22
$5e9f:  4f           DB  $4f
$5ea0:  35           DB  $35
$5ea1:  4f           DB  $4f
$5ea2:  50           DB  $50
$5ea3:  4f           DB  $4f
$5ea4:  61           DB  $61
$5ea5:  4f           DB  $4f
$5ea6:  76           DB  $76
$5ea7:  4f           DB  $4f
$5ea8:  87           DB  $87
$5ea9:  4f           DB  $4f
$5eaa:  aa           DB  $aa
$5eab:  4f           DB  $4f
$5eac:  b3           DB  $b3
$5ead:  4f           DB  $4f
$5eae:  c0           DB  $c0
$5eaf:  4f           DB  $4f
$5eb0:  cb           DB  $cb
$5eb1:  4f           DB  $4f
$5eb2:  dc           DB  $dc
$5eb3:  4f           DB  $4f
$5eb4:  ef           DB  $ef
$5eb5:  4f           DB  $4f
$5eb6:  fa           DB  $fa
$5eb7:  4f           DB  $4f
$5eb8:  07           DB  $07
$5eb9:  50           DB  $50
$5eba:  1a           DB  $1a
$5ebb:  50           DB  $50
$5ebc:  37           DB  $37
$5ebd:  50           DB  $50
$5ebe:  42           DB  $42
$5ebf:  50           DB  $50
$5ec0:  61           DB  $61
$5ec1:  50           DB  $50
$5ec2:  76           DB  $76
$5ec3:  50           DB  $50
$5ec4:  89           DB  $89
$5ec5:  50           DB  $50
$5ec6:  96           DB  $96
$5ec7:  50           DB  $50
$5ec8:  af           DB  $af
$5ec9:  50           DB  $50
$5eca:  cc           DB  $cc
$5ecb:  50           DB  $50
$5ecc:  f1           DB  $f1
$5ecd:  50           DB  $50
$5ece:  0a           DB  $0a
$5ecf:  51           DB  $51
$5ed0:  29           DB  $29
$5ed1:  51           DB  $51
$5ed2:  54           DB  $54
$5ed3:  51           DB  $51
$5ed4:  65           DB  $65
$5ed5:  51           DB  $51
$5ed6:  7e           DB  $7e
$5ed7:  51           DB  $51
$5ed8:  95           DB  $95
$5ed9:  51           DB  $51
$5eda:  94           DB  $94
$5edb:  48           DB  $48
$5edc:  97           DB  $97
$5edd:  48           DB  $48
$5ede:  c0           DB  $c0
$5edf:  48           DB  $48
$5ee0:  db           DB  $db
$5ee1:  48           DB  $48
$5ee2:  0e           DB  $0e
$5ee3:    DB  '$49' ; 'I', 0 ; null
$5ee5:  01           DB  $01
$5ee6:  02           DB  $02
$5ee7:  03           DB  $03
$5ee8:  04           DB  $04
$5ee9:  05           DB  $05
$5eea:  06           DB  $06
$5eeb:  07           DB  $07
$5eec:  08           DB  $08
$5eed:  09           DB  $09
$5eee:  0a           DB  $0a
$5eef:  0b           DB  $0b
$5ef0:  0c           DB  $0c
$5ef1:  0d           DB  $0d
$5ef2:  0e           DB  $0e
$5ef3:  0f           DB  $0f
$5ef4:  10           DB  $10
$5ef5:  11           DB  $11
$5ef6:  12           DB  $12
$5ef7:  13           DB  $13
$5ef8:  14           DB  $14
$5ef9:  15           DB  $15
$5efa:  16           DB  $16
$5efb:  17           DB  $17
$5efc:  18           DB  $18
$5efd:  19           DB  $19
$5efe:  1a           DB  $1a
$5eff:  1b           DB  $1b
$5f00:  1c           DB  $1c
$5f01:  1d           DB  $1d
$5f02:  1e           DB  $1e
$5f03:  1f           DB  $1f
$5f04:  20           DB  $20
$5f05:  21           DB  $21
$5f06:  22           DB  $22
$5f07:  23           DB  $23
$5f08:  24           DB  $24
$5f09:  25           DB  $25
$5f0a:  26           DB  $26
$5f0b:  27           DB  $27
$5f0c:  28           DB  $28
$5f0d:  29           DB  $29
$5f0e:  2a           DB  $2a
$5f0f:  2b           DB  $2b
$5f10:  2c           DB  $2c
$5f11:  2d           DB  $2d
$5f12:  2e           DB  $2e
$5f13:  2f           DB  $2f
$5f14:  30           DB  $30
$5f15:  31           DB  $31
$5f16:  32           DB  $32
$5f17:  33           DB  $33
$5f18:  34           DB  $34
$5f19:  35           DB  $35
$5f1a:  36           DB  $36
$5f1b:  37           DB  $37
$5f1c:    DB  '$38' ; '8', '$39' ; '9', '$3a' ; ':', '$3b' ; ';', '$3c' ; '<', '$3d' ; '=', '$3e' ; '>', '$3f' ; '?', '$40' ; '@', '$41' ; 'A', '$42' ; 'B', '$43' ; 'C', '$44' ; 'D', '$45' ; 'E', '$46' ; 'F', '$47' ; 'G', '$48' ; 'H', '$49' ; 'I', '$4a' ; 'J', '$4b' ; 'K', '$4c' ; 'L', '$4d' ; 'M', '$4e' ; 'N', '$4f' ; 'O', '$50' ; 'P', '$51' ; 'Q', '$52' ; 'R', '$53' ; 'S', '$54' ; 'T', '$55' ; 'U', '$56' ; 'V', '$57' ; 'W', '$58' ; 'X', '$59' ; 'Y', '$5a' ; 'Z', '$5b' ; '[', '$5c' ; '\', '$5d' ; ']', '$5e' ; '^', 0 ; null
$5f44:  00           DB  $00
$5f45:  01           DB  $01
$5f46:  02           DB  $02
$5f47:  03           DB  $03
$5f48:  04           DB  $04
$5f49:  05           DB  $05
$5f4a:  06           DB  $06
$5f4b:  07           DB  $07
$5f4c:  08           DB  $08
$5f4d:  09           DB  $09
$5f4e:  0a           DB  $0a
$5f4f:  0b           DB  $0b
$5f50:  0c           DB  $0c
$5f51:  0d           DB  $0d
$5f52:  0e           DB  $0e
$5f53:  0f           DB  $0f
$5f54:  10           DB  $10
$5f55:  11           DB  $11
$5f56:  12           DB  $12
$5f57:  13           DB  $13
$5f58:  14           DB  $14
$5f59:  15           DB  $15
$5f5a:  16           DB  $16
$5f5b:  17           DB  $17
$5f5c:  18           DB  $18
$5f5d:  19           DB  $19
$5f5e:  1a           DB  $1a
$5f5f:  1b           DB  $1b
$5f60:  1c           DB  $1c
$5f61:  1d           DB  $1d
$5f62:  1e           DB  $1e
$5f63:  1f           DB  $1f
$5f64:  60           DB  $60
$5f65:  61           DB  $61
$5f66:  62           DB  $62
$5f67:  63           DB  $63
$5f68:  64           DB  $64
$5f69:  65           DB  $65
$5f6a:  66           DB  $66
$5f6b:  67           DB  $67
$5f6c:  68           DB  $68
$5f6d:  69           DB  $69
$5f6e:  6a           DB  $6a
$5f6f:  6b           DB  $6b
$5f70:  6c           DB  $6c
$5f71:  6d           DB  $6d
$5f72:  6e           DB  $6e
$5f73:  6f           DB  $6f
$5f74:  70           DB  $70
$5f75:  71           DB  $71
$5f76:  72           DB  $72
$5f77:  73           DB  $73
$5f78:  74           DB  $74
$5f79:  75           DB  $75
$5f7a:  76           DB  $76
$5f7b:  77           DB  $77
$5f7c:  78           DB  $78
$5f7d:  79           DB  $79
$5f7e:  7a           DB  $7a
$5f7f:  7b           DB  $7b
$5f80:  7c           DB  $7c
$5f81:  7d           DB  $7d
$5f82:  7e           DB  $7e
$5f83:  7f           DB  $7f
$5f84:  80           DB  $80
$5f85:  81           DB  $81
$5f86:  82           DB  $82
$5f87:  83           DB  $83
$5f88:  84           DB  $84
$5f89:  85           DB  $85
$5f8a:  86           DB  $86
$5f8b:  87           DB  $87
$5f8c:  88           DB  $88
$5f8d:  89           DB  $89
$5f8e:  8a           DB  $8a
$5f8f:  8b           DB  $8b
$5f90:  8c           DB  $8c
$5f91:  8d           DB  $8d
$5f92:  8e           DB  $8e
$5f93:  8f           DB  $8f
$5f94:  90           DB  $90
$5f95:  91           DB  $91
$5f96:  92           DB  $92
$5f97:  93           DB  $93
$5f98:  94           DB  $94
$5f99:  95           DB  $95
$5f9a:  96           DB  $96
$5f9b:  97           DB  $97
$5f9c:  98           DB  $98
$5f9d:  99           DB  $99
$5f9e:  9a           DB  $9a
$5f9f:  9b           DB  $9b
$5fa0:  9c           DB  $9c
$5fa1:  9d           DB  $9d
$5fa2:  9e           DB  $9e
$5fa3:  9f           DB  $9f
$5fa4:  00           DB  $00
$5fa5:  01           DB  $01
$5fa6:  02           DB  $02
$5fa7:  03           DB  $03
$5fa8:  04           DB  $04
$5fa9:  05           DB  $05
$5faa:  06           DB  $06
$5fab:  07           DB  $07
$5fac:  08           DB  $08
$5fad:  09           DB  $09
$5fae:  0a           DB  $0a
$5faf:  0b           DB  $0b
$5fb0:  0c           DB  $0c
$5fb1:  0d           DB  $0d
$5fb2:  0e           DB  $0e
$5fb3:  0f           DB  $0f
$5fb4:  10           DB  $10
$5fb5:  11           DB  $11
$5fb6:  12           DB  $12
$5fb7:  13           DB  $13
$5fb8:  14           DB  $14
$5fb9:  15           DB  $15
$5fba:  16           DB  $16
$5fbb:  17           DB  $17
$5fbc:  18           DB  $18
$5fbd:  19           DB  $19
$5fbe:  1a           DB  $1a
$5fbf:  1b           DB  $1b
$5fc0:  1c           DB  $1c
$5fc1:  1d           DB  $1d
$5fc2:  1e           DB  $1e
$5fc3:  1f           DB  $1f
$5fc4:  20           DB  $20
$5fc5:  21           DB  $21
$5fc6:  22           DB  $22
$5fc7:  23           DB  $23
$5fc8:  24           DB  $24
$5fc9:  25           DB  $25
$5fca:  26           DB  $26
$5fcb:  27           DB  $27
$5fcc:  28           DB  $28
$5fcd:  29           DB  $29
$5fce:  2a           DB  $2a
$5fcf:  2b           DB  $2b
$5fd0:  2c           DB  $2c
$5fd1:  2d           DB  $2d
$5fd2:  2e           DB  $2e
$5fd3:  2f           DB  $2f
$5fd4:  30           DB  $30
$5fd5:  31           DB  $31
$5fd6:  32           DB  $32
$5fd7:  33           DB  $33
$5fd8:  34           DB  $34
$5fd9:  35           DB  $35
$5fda:  36           DB  $36
$5fdb:  37           DB  $37
$5fdc:  38           DB  $38
$5fdd:  39           DB  $39
$5fde:  3a           DB  $3a
$5fdf:  3b           DB  $3b
$5fe0:  3c           DB  $3c
$5fe1:  3d           DB  $3d
$5fe2:  3e           DB  $3e
$5fe3:  3f           DB  $3f
$5fe4:  40           DB  $40
$5fe5:  41           DB  $41
$5fe6:  42           DB  $42
$5fe7:  43           DB  $43
$5fe8:  44           DB  $44
$5fe9:  45           DB  $45
$5fea:  46           DB  $46
$5feb:  47           DB  $47
$5fec:  48           DB  $48
$5fed:  49           DB  $49
$5fee:  4a           DB  $4a
$5fef:  4b           DB  $4b
$5ff0:  4c           DB  $4c
$5ff1:  4d           DB  $4d
$5ff2:  4e           DB  $4e
$5ff3:  4f           DB  $4f
$5ff4:  50           DB  $50
$5ff5:  51           DB  $51
$5ff6:  52           DB  $52
$5ff7:  53           DB  $53
$5ff8:  54           DB  $54
$5ff9:  55           DB  $55
$5ffa:  56           DB  $56
$5ffb:  57           DB  $57
$5ffc:  58           DB  $58
$5ffd:  59           DB  $59
$5ffe:  5a           DB  $5a
$5fff:  5b           DB  $5b