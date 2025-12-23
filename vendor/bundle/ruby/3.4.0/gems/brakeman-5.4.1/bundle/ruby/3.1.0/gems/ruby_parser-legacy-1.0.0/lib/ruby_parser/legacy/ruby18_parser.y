# -*- racc -*-

class Ruby18Parser

token kCLASS kMODULE kDEF kUNDEF kBEGIN kRESCUE kENSURE kEND kIF kUNLESS
      kTHEN kELSIF kELSE kCASE kWHEN kWHILE kUNTIL kFOR kBREAK kNEXT
      kREDO kRETRY kIN kDO kDO_COND kDO_BLOCK kRETURN kYIELD kSUPER
      kSELF kNIL kTRUE kFALSE kAND kOR kNOT kIF_MOD kUNLESS_MOD kWHILE_MOD
      kUNTIL_MOD kRESCUE_MOD kALIAS kDEFINED klBEGIN klEND k__LINE__
      k__FILE__ tIDENTIFIER tFID tGVAR tIVAR tCONSTANT tCVAR tNTH_REF
      tBACK_REF tSTRING_CONTENT tINTEGER tFLOAT tREGEXP_END tUPLUS
      tUMINUS tUMINUS_NUM tPOW tCMP tEQ tEQQ tNEQ tGEQ tLEQ tANDOP
      tOROP tMATCH tNMATCH tDOT tDOT2 tDOT3 tAREF tASET tLSHFT tRSHFT
      tCOLON2 tCOLON3 tOP_ASGN tASSOC tLPAREN tLPAREN2 tRPAREN tLPAREN_ARG
      tLBRACK tLBRACK2 tRBRACK tLBRACE tLBRACE_ARG tSTAR tSTAR2 tAMPER tAMPER2
      tTILDE tPERCENT tDIVIDE tPLUS tMINUS tLT tGT tPIPE tBANG tCARET
      tLCURLY tRCURLY tBACK_REF2 tSYMBEG tSTRING_BEG tXSTRING_BEG tREGEXP_BEG
      tWORDS_BEG tQWORDS_BEG tSTRING_DBEG tSTRING_DVAR tSTRING_END tSTRING
      tSYMBOL tNL tEH tCOLON tCOMMA tSPACE tSEMI tLAST_TOKEN

prechigh
  right    tBANG tTILDE tUPLUS
  right    tPOW
  right    tUMINUS_NUM tUMINUS
  left     tSTAR2 tDIVIDE tPERCENT
  left     tPLUS tMINUS
  left     tLSHFT tRSHFT
  left     tAMPER2
  left     tPIPE tCARET
  left     tGT tGEQ tLT tLEQ
  nonassoc tCMP tEQ tEQQ tNEQ tMATCH tNMATCH
  left     tANDOP
  left     tOROP
  nonassoc tDOT2 tDOT3
  right    tEH tCOLON
  left     kRESCUE_MOD
  right    tEQL tOP_ASGN
  nonassoc kDEFINED
  right    kNOT
  left     kOR kAND
  nonassoc kIF_MOD kUNLESS_MOD kWHILE_MOD kUNTIL_MOD
  nonassoc tLBRACE_ARG
  nonassoc tLOWEST
preclow

rule

         program:   {
                      self.lexer.lex_state = :expr_beg
                    }
                    compstmt
                    {
                      result = val[1]
                    }

        bodystmt: compstmt opt_rescue opt_else opt_ensure
                    {
                      result = new_body val
                    }

        compstmt: stmts opt_terms
                    {
                      result = new_compstmt val
                    }

           stmts: none
                | stmt
                | stmts terms stmt
                    {
                      result = block_append val[0], val[2]
                    }
                | error stmt
                    {
                      result = val[1]
                    }

            stmt: kALIAS fitem
                    {
                      lexer.lex_state = :expr_fname
                      result = self.lexer.lineno
                    }
                    fitem
                    {
                      result = s(:alias, val[1], val[3]).line(val[2])
                    }
                | kALIAS tGVAR tGVAR
                    {
                      result = s(:valias, val[1].to_sym, val[2].to_sym)
                    }
                | kALIAS tGVAR tBACK_REF
                    {
                      result = s(:valias, val[1].to_sym, :"$#{val[2]}")
                    }
                | kALIAS tGVAR tNTH_REF
                    {
                      yyerror "can't make alias for the number variables"
                    }
                | kUNDEF undef_list
                    {
                      result = val[1]
                    }
                | stmt kIF_MOD expr_value
                    {
                      result = new_if val[2], val[0], nil
                    }
                | stmt kUNLESS_MOD expr_value
                    {
                      result = new_if val[2], nil, val[0]
                    }
                | stmt kWHILE_MOD expr_value
                    {
                      result = new_while val[0], val[2], true
                    }
                | stmt kUNTIL_MOD expr_value
                    {
                      result = new_until val[0], val[2], true
                    }
                | stmt kRESCUE_MOD stmt
                    {
                      result = s(:rescue, val[0], new_resbody(s(:array), val[2]))
                    }
                | klBEGIN
                    {
                      if (in_def || in_single > 0) then
                        yyerror "BEGIN in method"
                      end
                      self.env.extend
                    }
                    tLCURLY compstmt tRCURLY
                    {
                      result = new_iter s(:preexe), 0, val[3]
                    }
                | klEND tLCURLY compstmt tRCURLY
                    {
                      if (in_def || in_single > 0) then
                        yyerror "END in method; use at_exit"
                      end
                      result = new_iter s(:postexe), 0, val[2]
                    }
                | lhs tEQL command_call
                    {
                      result = new_assign val[0], val[2]
                    }
                | mlhs tEQL command_call
                    {
                      result = new_masgn val[0], val[2], :wrap
                    }
                | var_lhs tOP_ASGN command_call
                    {
                      result = new_op_asgn val
                    }
                | primary_value tLBRACK2 aref_args tRBRACK tOP_ASGN command_call
                    {
                      result = s(:op_asgn1, val[0], val[2], val[4].to_sym, val[5])
                    }
                | primary_value tDOT tIDENTIFIER tOP_ASGN command_call
                    {
                      result = s(:op_asgn, val[0], val[4], val[2].to_sym, val[3].to_sym)
                    }
                | primary_value tDOT tCONSTANT tOP_ASGN command_call
                    {
                      result = s(:op_asgn, val[0], val[4], val[2].to_sym, val[3].to_sym)
                    }
                | primary_value tCOLON2 tIDENTIFIER tOP_ASGN command_call
                    {
                      result = s(:op_asgn, val[0], val[4], val[2], val[3])
                    }
                | backref tOP_ASGN command_call
                    {
                      backref_assign_error val[0]
                    }
                | lhs tEQL mrhs
                    {
                      result = new_assign val[0], s(:svalue, val[2])
                    }
                | mlhs tEQL arg_value
                    {
                      result = new_masgn val[0], val[2], :wrap
                    }
                | mlhs tEQL mrhs
                    {
                      result = new_masgn val[0], val[2]
                    }
                | expr

            expr: command_call
                | expr kAND expr
                    {
                      result = logical_op :and, val[0], val[2]
                    }
                | expr kOR expr
                    {
                      result = logical_op :or, val[0], val[2]
                    }
                | kNOT expr
                    {
                      result = s(:not, val[1])
                    }
                | tBANG command_call
                    {
                      result = s(:not, val[1])
                    }
                | arg

      expr_value: expr
                    {
                      result = value_expr(val[0])
                    }

    command_call: command
                | block_command
                | kRETURN call_args
                    {
                      line = val[0].last
                      result = s(:return, ret_args(val[1])).line(line)
                    }
                | kBREAK call_args
                    {
                      line = val[0].last
                      result = s(:break, ret_args(val[1])).line(line)
                    }
                | kNEXT call_args
                    {
                      line = val[0].last
                      result = s(:next, ret_args(val[1])).line(line)
                    }

   block_command: block_call
                | block_call tDOT operation2 command_args
                    {
                      result = new_call val[0], val[2], val[3]
                    }
                | block_call tCOLON2 operation2 command_args
                    {
                      result = new_call val[0], val[2], val[3]
                    }

 cmd_brace_block: tLBRACE_ARG
                    {
                      self.env.extend(:dynamic)
                      result = self.lexer.lineno
                    }
                    opt_block_var
                    {
                      result = nil # self.env.dynamic.keys
                    }
                    compstmt tRCURLY
                    {
                      result = new_iter nil, val[2], val[4]
                      self.env.unextend
                    }

         command: operation command_args =tLOWEST
                    {
                      result = new_call nil, val[0].to_sym, val[1]
                    }
                | operation command_args cmd_brace_block
                    {
                      result = new_call nil, val[0].to_sym, val[1]

                      if val[2] then
                        block_dup_check result, val[2]

                        result, operation = val[2], result
                        result.insert 1, operation
                      end
                    }
                | primary_value tDOT operation2 command_args =tLOWEST
                    {
                      result = new_call val[0], val[2].to_sym, val[3]
                    }
                | primary_value tDOT operation2 command_args cmd_brace_block
                    {
                      result = new_call val[0], val[2].to_sym, val[3]
                      raise "no2"

                      if val[4] then
                        block_dup_check result, val[4]

                        val[2] << result
                        result = val[2]
                      end
                    }
                | primary_value tCOLON2 operation2 command_args =tLOWEST
                    {
                      result = new_call val[0], val[2].to_sym, val[3]
                    }
                | primary_value tCOLON2 operation2 command_args cmd_brace_block
                    {
                      result = new_call val[0], val[2].to_sym, val[3]
                      raise "no3"

                      if val[4] then
                        block_dup_check result, val[4]

                        val[2] << result
                        result = val[2]
                      end
                    }
                | kSUPER command_args
                    {
                      result = new_super val[1]
                    }
                | kYIELD command_args
                    {
                      result = new_yield val[1]
                    }

            mlhs: mlhs_basic
                | tLPAREN mlhs_entry tRPAREN
                    {
                      result = val[1]
                    }

      mlhs_entry: mlhs_basic
                | tLPAREN mlhs_entry tRPAREN
                    {
                      result = s(:masgn, s(:array, val[1]))
                    }

      mlhs_basic: mlhs_head
                    {
                      result = s(:masgn, val[0])
                    }
                | mlhs_head mlhs_item
                    {
                      result = s(:masgn, val[0] << val[1].compact)
                    }
                | mlhs_head tSTAR mlhs_node
                    {
                      result = s(:masgn, val[0] << s(:splat, val[2]))
                    }
                | mlhs_head tSTAR
                    {
                      result = s(:masgn, val[0] << s(:splat))
                    }
                | tSTAR mlhs_node
                    {
                      result = s(:masgn, s(:array, s(:splat, val[1])))
                    }
                | tSTAR
                    {
                      result = s(:masgn, s(:array, s(:splat)))
                    }

       mlhs_item: mlhs_node
                | tLPAREN mlhs_entry tRPAREN
                    {
                      result = val[1]
                    }

       mlhs_head: mlhs_item tCOMMA
                    {
                      result = s(:array, val[0])
                    }
                | mlhs_head mlhs_item tCOMMA
                    {
                      result = val[0] << val[1].compact
                    }

       mlhs_node: variable
                    {
                      result = assignable val[0]
                    }
                | primary_value tLBRACK2 aref_args tRBRACK
                    {
                      result = aryset val[0], val[2]
                    }
                | primary_value tDOT tIDENTIFIER
                    {
                      result = s(:attrasgn, val[0], :"#{val[2]}=")
                    }
                | primary_value tCOLON2 tIDENTIFIER
                    {
                      result = s(:attrasgn, val[0], :"#{val[2]}=")
                    }
                | primary_value tDOT tCONSTANT
                    {
                      result = s(:attrasgn, val[0], :"#{val[2]}=")
                    }
                | primary_value tCOLON2 tCONSTANT
                    {
                      if (in_def || in_single > 0) then
                        yyerror "dynamic constant assignment"
                      end

                      result = s(:const, s(:colon2, val[0], val[2].to_sym), nil)
                    }
                | tCOLON3 tCONSTANT
                    {
                      if (in_def || in_single > 0) then
                        yyerror "dynamic constant assignment"
                      end

                      result = s(:const, nil, s(:colon3, val[1].to_sym))
                    }
                | backref
                    {
                      backref_assign_error val[0]
                    }

             lhs: variable
                    {
                      result = assignable val[0]
                    }
                | primary_value tLBRACK2 aref_args tRBRACK
                    {
                      result = aryset val[0], val[2]
                    }
                | primary_value tDOT tIDENTIFIER
                    {
                      result = s(:attrasgn, val[0], :"#{val[2]}=")
                    }
                | primary_value tCOLON2 tIDENTIFIER
                    {
                      result = s(:attrasgn, val[0], :"#{val[2]}=")
                    }
                | primary_value tDOT tCONSTANT
                    {
                      result = s(:attrasgn, val[0], :"#{val[2]}=")
                    }
                | primary_value tCOLON2 tCONSTANT
                    {
                      if (in_def || in_single > 0) then
                        yyerror "dynamic constant assignment"
                      end

                      result = s(:const, s(:colon2, val[0], val[2].to_sym))
                    }
                | tCOLON3 tCONSTANT
                    {
                      if (in_def || in_single > 0) then
                        yyerror "dynamic constant assignment"
                      end

                      result = s(:const, s(:colon3, val[1].to_sym))
                    }
                | backref
                    {
                      backref_assign_error val[0]
                    }

           cname: tIDENTIFIER
                    {
                      yyerror "class/module name must be CONSTANT"
                    }
                | tCONSTANT

           cpath: tCOLON3 cname
                    {
                      result = s(:colon3, val[1].to_sym)
                    }
                | cname
                    {
                      result = val[0].to_sym
                    }
                | primary_value tCOLON2 cname
                    {
                      result = s(:colon2, val[0], val[2].to_sym)
                    }

           fname: tIDENTIFIER | tCONSTANT | tFID
                | op
                    {
                      lexer.lex_state = :expr_end
                      result = val[0]
                    }

                | reswords
                    {
                      (sym, _line), = val
                      lexer.lex_state = :expr_end
                      result = sym
                    }

            fsym: fname | symbol

           fitem: fsym { result = s(:lit, val[0].to_sym) }
                | dsym

      undef_list: fitem
                    {
                      result = new_undef val[0]
                    }
                |
                    undef_list tCOMMA
                    {
                      lexer.lex_state = :expr_fname
                    }
                    fitem
                    {
                      result = new_undef val[0], val[3]
                    }

              op: tPIPE    | tCARET     | tAMPER2 | tCMP   | tEQ     | tEQQ
                | tMATCH   | tGT        | tGEQ    | tLT    | tLEQ    | tLSHFT
                | tRSHFT   | tPLUS      | tMINUS  | tSTAR2 | tSTAR   | tDIVIDE
                | tPERCENT | tPOW       | tTILDE  | tUPLUS | tUMINUS | tAREF
                | tASET    | tBACK_REF2

        reswords: k__LINE__ | k__FILE__   | klBEGIN | klEND  | kALIAS  | kAND
                | kBEGIN    | kBREAK      | kCASE   | kCLASS | kDEF    | kDEFINED
                | kDO       | kELSE       | kELSIF  | kEND   | kENSURE | kFALSE
                | kFOR      | kIN         | kMODULE | kNEXT  | kNIL    | kNOT
                | kOR       | kREDO       | kRESCUE | kRETRY | kRETURN | kSELF
                | kSUPER    | kTHEN       | kTRUE   | kUNDEF | kWHEN   | kYIELD
                | kIF       | kUNLESS     | kWHILE  | kUNTIL

             arg: lhs tEQL arg
                    {
                      result = new_assign val[0], val[2]
                    }
                | lhs tEQL arg kRESCUE_MOD arg
                    {
                      result = new_assign val[0], s(:rescue, val[2], new_resbody(s(:array), val[4]))
                      # result.line = val[0].line
                    }
                | var_lhs tOP_ASGN arg
                    {
                      result = new_op_asgn val
                    }
                | primary_value tLBRACK2 aref_args tRBRACK tOP_ASGN arg
                    {
                      result = s(:op_asgn1, val[0], val[2], val[4].to_sym, val[5])
                      val[2].sexp_type = :arglist if val[2]
                    }
                | primary_value tDOT tIDENTIFIER tOP_ASGN arg
                    {
                      result = s(:op_asgn2, val[0], :"#{val[2]}=", val[3].to_sym, val[4])
                    }
                | primary_value tDOT tCONSTANT tOP_ASGN arg
                    {
                      result = s(:op_asgn2, val[0], :"#{val[2]}=", val[3].to_sym, val[4])
                    }
                | primary_value tCOLON2 tIDENTIFIER tOP_ASGN arg
                    {
                      result = s(:op_asgn, val[0], val[4], val[2].to_sym, val[3].to_sym)
                    }
                | primary_value tCOLON2 tCONSTANT tOP_ASGN arg
                    {
                      yyerror "constant re-assignment"
                    }
                | tCOLON3 tCONSTANT tOP_ASGN arg
                    {
                      yyerror "constant re-assignment"
                    }
                | backref tOP_ASGN arg
                    {
                      backref_assign_error val[0]
                    }
                | arg tDOT2 arg
                    {
                      v1, v2 = val[0], val[2]
                      if v1.node_type == :lit and v2.node_type == :lit and Integer === v1.last and Integer === v2.last then
                        result = s(:lit, (v1.last)..(v2.last))
                      else
                        result = s(:dot2, v1, v2)
                      end
                    }
                | arg tDOT3 arg
                    {
                      v1, v2 = val[0], val[2]
                      if v1.node_type == :lit and v2.node_type == :lit and Integer === v1.last and Integer === v2.last then
                        result = s(:lit, (v1.last)...(v2.last))
                      else
                        result = s(:dot3, v1, v2)
                      end
                    }
                | arg tPLUS arg
                    {
                      result = new_call val[0], :+, argl(val[2])
                    }
                | arg tMINUS arg
                    {
                      result = new_call val[0], :-, argl(val[2])
                    }
                | arg tSTAR2 arg
                    {
                      result = new_call val[0], :*, argl(val[2])
                    }
                | arg tDIVIDE arg
                    {
                      result = new_call val[0], :"/", argl(val[2])
                    }
                | arg tPERCENT arg
                    {
                      result = new_call val[0], :"%", argl(val[2])
                    }
                | arg tPOW arg
                    {
                      result = new_call val[0], :**, argl(val[2])
                    }
                | tUMINUS_NUM tINTEGER tPOW arg
                    {
                      result = new_call(new_call(s(:lit, val[1]), :"**", argl(val[3])), :"-@")
                    }
                | tUMINUS_NUM tFLOAT tPOW arg
                    {
                      result = new_call(new_call(s(:lit, val[1]), :"**", argl(val[3])), :"-@")
                    }
                | tUPLUS arg
                    {
                      if val[1].sexp_type == :lit then
                        result = val[1]
                      else
                        result = new_call val[1], :"+@"
                      end
                    }
                | tUMINUS arg
                    {
                      result = new_call val[1], :"-@"
                    }
                | arg tPIPE arg
                    {
                      result = new_call val[0], :"|", argl(val[2])
                    }
                | arg tCARET arg
                    {
                      result = new_call val[0], :"^", argl(val[2])
                    }
                | arg tAMPER2 arg
                    {
                      result = new_call val[0], :"&", argl(val[2])
                    }
                | arg tCMP arg
                    {
                      result = new_call val[0], :"<=>", argl(val[2])
                    }
                | arg tGT arg
                    {
                      result = new_call val[0], :">", argl(val[2])
                    }
                | arg tGEQ arg
                    {
                      result = new_call val[0], :">=", argl(val[2])
                    }
                | arg tLT arg
                    {
                      result = new_call val[0], :"<", argl(val[2])
                    }
                | arg tLEQ arg
                    {
                      result = new_call val[0], :"<=", argl(val[2])
                    }
                | arg tEQ arg
                    {
                      result = new_call val[0], :"==", argl(val[2])
                    }
                | arg tEQQ arg
                    {
                      result = new_call val[0], :"===", argl(val[2])
                    }
                | arg tNEQ arg
                    {
                      val[0] = value_expr val[0] # TODO: port call_op and clean these
                      val[2] = value_expr val[2]
                      result = s(:not, new_call(val[0], :"==", argl(val[2])))
                    }
                | arg tMATCH arg
                    {
                      result = new_match val[0], val[2]
                    }
                | arg tNMATCH arg
                    {
                      result = s(:not, new_match(val[0], val[2]))
                    }
                | tBANG arg
                    {
                      result = s(:not, val[1])
                    }
                | tTILDE arg
                    {
                      val[2] = value_expr val[2]
                      result = new_call val[1], :"~"
                    }
                | arg tLSHFT arg
                    {
                      val[0] = value_expr val[0]
                      val[2] = value_expr val[2]
                      result = new_call val[0], :"\<\<", argl(val[2])
                    }
                | arg tRSHFT arg
                    {
                      val[0] = value_expr val[0]
                      val[2] = value_expr val[2]
                      result = new_call val[0], :">>", argl(val[2])
                    }
                | arg tANDOP arg
                    {
                      result = logical_op :and, val[0], val[2]
                    }
                | arg tOROP arg
                    {
                      result = logical_op :or, val[0], val[2]
                    }
                | kDEFINED opt_nl arg
                    {
                      result = s(:defined, val[2])
                    }
                | arg tEH arg tCOLON arg
                    {
                      result = s(:if, val[0], val[2], val[4])
                    }
                | primary

       arg_value: arg
                    {
                      result = value_expr(val[0])
                    }

       aref_args: none
                | command opt_nl
                    {
                      warning 'parenthesize argument(s) for future version'
                      result = s(:array, val[0])
                    }
                | args trailer
                    {
                      result = val[0]
                    }
                | args tCOMMA tSTAR arg opt_nl
                    {
                      result = arg_concat val[0], val[3]
                    }
                | assocs trailer
                    {
                      result = s(:array, s(:hash, *val[0].values))
                    }
                | tSTAR arg opt_nl
                    {
                      result = s(:array, s(:splat, val[1]))
                    }

      paren_args: tLPAREN2 none tRPAREN
                    {
                      result = val[1]
                    }
                | tLPAREN2 call_args opt_nl tRPAREN
                    {
                      result = val[1]
                    }
                | tLPAREN2 block_call opt_nl tRPAREN
                    {
                      warning "parenthesize argument(s) for future version"
                      result = s(:array, val[1])
                    }
                | tLPAREN2 args tCOMMA block_call opt_nl tRPAREN
                    {
                      warning "parenthesize argument(s) for future version"
                      result = val[1].add val[3]
                    }

  opt_paren_args: none
                | paren_args

       call_args: command
                    {
                      warning "parenthesize argument(s) for future version"
                      result = s(:array, val[0])
                    }
                | args opt_block_arg
                    {
                      result = arg_blk_pass val[0], val[1]
                    }
                | args tCOMMA tSTAR arg_value opt_block_arg
                    {
                      result = arg_concat val[0], val[3]
                      result = arg_blk_pass result, val[4]
                    }
                | assocs opt_block_arg
                    {
                      result = s(:array, s(:hash, *val[0].values))
                      result = arg_blk_pass result, val[1]
                    }
                | assocs tCOMMA tSTAR arg_value opt_block_arg
                    {
                      result = arg_concat s(:array, s(:hash, *val[0].values)), val[3]
                      result = arg_blk_pass result, val[4]
                    }
                | args tCOMMA assocs opt_block_arg
                    {
                      result = val[0] << s(:hash, *val[2].values)
                      result = arg_blk_pass result, val[3]
                    }
                | args tCOMMA assocs tCOMMA tSTAR arg opt_block_arg
                    {
                      val[0] << s(:hash, *val[2].values)
                      result = arg_concat val[0], val[5]
                      result = arg_blk_pass result, val[6]
                    }
                | tSTAR arg_value opt_block_arg
                    {
                      result = arg_blk_pass s(:splat, val[1]), val[2]
                    }
                | block_arg

      call_args2: arg_value tCOMMA args opt_block_arg
                    {
                      args = list_prepend val[0], val[2]
                      result = arg_blk_pass args, val[3]
                    }
                | arg_value tCOMMA block_arg
                    {
                      result = arg_blk_pass val[0], val[2]
                    }
                | arg_value tCOMMA tSTAR arg_value opt_block_arg
                    {
                      result = arg_concat s(:array, val[0]), val[3]
                      result = arg_blk_pass result, val[4]
                    }
                | arg_value tCOMMA args tCOMMA tSTAR arg_value opt_block_arg
                    {
                      result = arg_concat s(:array, val[0], s(:hash, *val[2].values)), val[5]
                      result = arg_blk_pass result, val[6]
                    }
                | assocs opt_block_arg
                    {
                      result = s(:array, s(:hash, *val[0].values))
                      result = arg_blk_pass result, val[1]
                    }
                | assocs tCOMMA tSTAR arg_value opt_block_arg
                    {
                      result = s(:array, s(:hash, *val[0].values), val[3])
                      result = arg_blk_pass result, val[4]
                    }
                | arg_value tCOMMA assocs opt_block_arg
                    {
                      result = s(:array, val[0], s(:hash, *val[2].values))
                      result = arg_blk_pass result, val[3]
                    }
                | arg_value tCOMMA args tCOMMA assocs opt_block_arg
                    {
                      arg_value, _, args, _, assocs, opt_block = val
                      result = s(:array, arg_value).add_all(args)
                      result.add(s(:hash, *assocs.sexp_body))
                      result = arg_blk_pass result, opt_block
                    }
                | arg_value tCOMMA assocs tCOMMA tSTAR arg_value opt_block_arg
                    {
                      result = arg_concat s(:array, val[0]).add(s(:hash, *val[2].sexp_body)), val[5]
                      result = arg_blk_pass result, val[6]
                    }
                | arg_value tCOMMA args tCOMMA assocs tCOMMA tSTAR arg_value opt_block_arg
                    {
                      result = arg_concat s(:array, val[0]).add_all(val[2]).add(s(:hash, *val[4].values)), val[7]
                      result = arg_blk_pass result, val[8]
                    }
                | tSTAR arg_value opt_block_arg
                    {
                      result = arg_blk_pass s(:splat, val[1]), val[2]
                    }
                | block_arg

    command_args:   {
                      result = lexer.cmdarg.stack.dup
                      lexer.cmdarg.push true
                    }
                    open_args
                    {
                      lexer.cmdarg.stack.replace val[0]
                      result = val[1]
                    }

       open_args: call_args
                | tLPAREN_ARG
                    {
                      lexer.lex_state = :expr_endarg
                    }
                    tRPAREN
                    {
                      warning "don't put space before argument parentheses"
                      result = nil
                    }
                | tLPAREN_ARG call_args2
                    {
                      lexer.lex_state = :expr_endarg
                    }
                    tRPAREN
                    {
                      warning "don't put space before argument parentheses"
                      result = val[1]
                    }

       block_arg: tAMPER arg_value
                    {
                      result = s(:block_pass, val[1])
                    }

   opt_block_arg: tCOMMA block_arg
                    {
                      result = val[1]
                    }
                | none

            args: arg_value
                    {
                      result = s(:array, val[0])
                    }
                | args tCOMMA arg_value
                    {
                      result = list_append val[0], val[2]
                    }

            mrhs: args tCOMMA arg_value
                    {
                      result = val[0] << val[2]
                    }
                | args tCOMMA tSTAR arg_value
                    {
                      result = arg_concat val[0], val[3]
                    }
                | tSTAR arg_value
                    {
                      result = s(:splat, val[1])
                    }

         primary: literal
                | strings
                | xstring
                | regexp
                | words
                | qwords
                | var_ref
                | backref
                | tFID
                    {
                      result = new_call nil, val[0].to_sym
                    }
                | kBEGIN
                    {
                      result = self.lexer.lineno
                    }
                    bodystmt kEND
                    {
                      unless val[2] then
                        result = s(:nil)
                      else
                        result = s(:begin, val[2])
                      end

                      result.line = val[1]
                    }
                | tLPAREN_ARG expr
                    {
                      lexer.lex_state = :expr_endarg
                    }
                    opt_nl tRPAREN
                    {
                      warning "(...) interpreted as grouped expression"
                      result = val[1]
                    }
                | tLPAREN compstmt tRPAREN
                    {
                      result = val[1] || s(:nil)
                      result.paren = true
                    }
                | primary_value tCOLON2 tCONSTANT
                    {
                      result = s(:colon2, val[0], val[2].to_sym)
                    }
                | tCOLON3 tCONSTANT
                    {
                      result = s(:colon3, val[1].to_sym)
                    }
                | primary_value tLBRACK2 aref_args tRBRACK
                    {
                      result = new_aref val
                    }
                | tLBRACK aref_args tRBRACK
                    {
                      result = val[1] || s(:array)
                    }
                | tLBRACE
                    {
                      result = self.lexer.lineno
                    }
                    assoc_list tRCURLY
                    {
                      result = new_hash val
                    }
                | kRETURN
                    {
                      result = s(:return)
                    }
                | kYIELD tLPAREN2 call_args tRPAREN
                    {
                      result = new_yield val[2]
                    }
                | kYIELD tLPAREN2 tRPAREN
                    {
                      result = new_yield
                    }
                | kYIELD
                    {
                      result = new_yield
                    }
                | kDEFINED opt_nl tLPAREN2 expr tRPAREN
                    {
                      result = s(:defined, val[3])
                    }
                | operation brace_block
                    {
                      oper, iter = val[0], val[1]
                      call = new_call(nil, oper.to_sym)
                      iter.insert 1, call
                      result = iter
                      call.line = iter.line
                    }
                | method_call
                | method_call brace_block
                    {
                      call, iter = val[0], val[1]
                      block_dup_check call, iter

                      iter.insert 1, call
                      result = iter
                    }
                | kIF expr_value then compstmt if_tail kEND
                    {
                      result = new_if val[1], val[3], val[4]
                    }
                | kUNLESS expr_value then compstmt opt_else kEND
                    {
                      result = new_if val[1], val[4], val[3]
                    }
                | kWHILE
                    {
                      lexer.cond.push true
                    }
                    expr_value do
                    {
                      lexer.cond.pop
                    }
                    compstmt kEND
                    {
                      result = new_while val[5], val[2], true
                    }
                | kUNTIL
                    {
                      lexer.cond.push true
                    }
                    expr_value do
                    {
                      lexer.cond.pop
                    }
                    compstmt kEND
                    {
                      result = new_until val[5], val[2], true
                    }
                | kCASE expr_value opt_terms case_body kEND
                    {
                      (_, line), expr, _, body, _ = val
                      result = new_case expr, body, line
                    }
                | kCASE            opt_terms case_body kEND
                    {
                      (_, line), _, body, _ = val
                      result = new_case nil, body, line
                    }
                | kCASE opt_terms kELSE compstmt kEND # TODO: need a test
                    {
                      (_, line), _, _, elsebody, _ = val
                      result = new_case nil, elsebody, line
                    }
                | kFOR for_var kIN
                    {
                      lexer.cond.push true
                    }
                    expr_value do
                    {
                      lexer.cond.pop
                    }
                    compstmt kEND
                    {
                      result = new_for val[4], val[1], val[7]
                    }
                | kCLASS
                    {
                      result = self.lexer.lineno
                    }
                    cpath superclass
                    {
                      self.comments.push self.lexer.comments
                      if (in_def || in_single > 0) then
                        yyerror "class definition in method body"
                      end
                      self.env.extend
                    }
                    bodystmt kEND
                    {
                      result = new_class val
                      self.env.unextend
                      self.lexer.comments # we don't care about comments in the body
                    }
                | kCLASS tLSHFT
                    {
                      result = self.lexer.lineno
                    }
                    expr
                    {
                      result = in_def
                      self.in_def = false
                    }
                    term
                    {
                      result = in_single
                      self.in_single = 0
                      self.env.extend
                    }
                    bodystmt kEND
                    {
                      result = new_sclass val
                      self.env.unextend
                      self.lexer.comments # we don't care about comments in the body
                    }
                | kMODULE
                    {
                      result = self.lexer.lineno
                    }
                    cpath
                    {
                      self.comments.push self.lexer.comments
                      yyerror "module definition in method body" if
                        in_def or in_single > 0

                      self.env.extend
                    }
                    bodystmt kEND
                    {
                      result = new_module val
                      self.env.unextend
                      self.lexer.comments # we don't care about comments in the body
                    }
                | kDEF fname
                    {
                      result = self.in_def

                      self.comments.push self.lexer.comments
                      self.in_def = true
                      self.env.extend
                    }
                    f_arglist bodystmt kEND
                    {
                      in_def = val[2]

                      result = new_defn val

                      self.env.unextend
                      self.in_def = in_def
                      self.lexer.comments # we don't care about comments in the body
                    }
                | kDEF singleton dot_or_colon
                    {
                      self.comments.push self.lexer.comments
                      lexer.lex_state = :expr_fname
                    }
                    fname
                    {
                      self.in_single += 1
                      self.env.extend
                      lexer.lex_state = :expr_end # force for args
                      result = [lexer.lineno, self.lexer.cmdarg.stack.dup]
                      lexer.cmdarg.stack.replace [false]
                    }
                    f_arglist bodystmt kEND
                    {
                      line, cmdarg = val[5]
                      result = new_defs val
                      result[3].line line

                      lexer.cmdarg.stack.replace cmdarg
                      self.env.unextend
                      self.in_single -= 1
                      self.lexer.comments # we don't care about comments in the body
                    }
                | kBREAK
                    {
                      result = s(:break)
                    }
                | kNEXT
                    {
                      result = s(:next)
                    }
                | kREDO
                    {
                      result = s(:redo)
                    }
                | kRETRY
                    {
                      result = s(:retry)
                    }

   primary_value: primary
                    {
                      result = value_expr(val[0])
                    }

            then: term
                | tCOLON
                | kTHEN
                | term kTHEN

              do: term
                | tCOLON
                | kDO_COND

         if_tail: opt_else
                | kELSIF expr_value then compstmt if_tail
                    {
                      result = s(:if, val[1], val[3], val[4])
                    }

        opt_else: none
                | kELSE compstmt
                    {
                      result = val[1]
                    }

         for_var: lhs
                | mlhs
                    {
                      val[0].delete_at 1 if val[0][1].nil? # HACK
                    }

       block_par: mlhs_item
                    {
                      result = s(:array, clean_mlhs(val[0]))
                    }
                | block_par tCOMMA mlhs_item
                    {
                      result = list_append val[0], clean_mlhs(val[2])
                    }

       block_var: block_par
                    {
                      result = block_var18 val[0], nil, nil
                    }
                | block_par tCOMMA
                    {
                      result = block_var18 val[0], nil, nil
                    }
                | block_par tCOMMA tAMPER lhs
                    {
                      result = block_var18 val[0], nil, val[3]
                    }
                | block_par tCOMMA tSTAR lhs tCOMMA tAMPER lhs
                    {
                      result = block_var18 val[0], val[3], val[6]
                    }
                | block_par tCOMMA tSTAR tCOMMA tAMPER lhs
                    {
                      result = block_var18 val[0], s(:splat), val[5]
                    }
                | block_par tCOMMA tSTAR lhs
                    {
                      result = block_var18 val[0], val[3], nil
                    }
                | block_par tCOMMA tSTAR
                    {
                      result = block_var18 val[0], s(:splat), nil
                    }
                | tSTAR lhs tCOMMA tAMPER lhs
                    {
                      result = block_var18 nil, val[1], val[4]
                    }
                | tSTAR tCOMMA tAMPER lhs
                    {
                      result = block_var18 nil, s(:splat), val[3]
                    }
                | tSTAR lhs
                    {
                      result = block_var18 nil, val[1], nil
                    }
                | tSTAR
                    {
                      result = block_var18 nil, s(:splat), nil
                    }
                | tAMPER lhs
                    {
                      result = block_var18 nil, nil, val[1]
                    }
                ;

   opt_block_var: none { result = 0 }
                | tPIPE tPIPE
                    {
                      result = s(:args)
                      self.lexer.command_start = true
                    }
                | tOROP
                    {
                      result = s(:args)
                      self.lexer.command_start = true
                    }
                | tPIPE block_var tPIPE
                    {
                      result = val[1]
                      self.lexer.command_start = true
                    }

        do_block: kDO_BLOCK
                    {
                      self.env.extend :dynamic
                      result = self.lexer.lineno
                    }
                    opt_block_var
                    {
                      result = nil # self.env.dynamic.keys
                    }
                    compstmt kEND
                    {
                      vars   = val[2]
                      body   = val[4]
                      result = new_iter nil, vars, body
                      result.line = val[1]

                      self.env.unextend
                    }

      block_call: command do_block
                    {
                      block_dup_check val[0], val[1]

                      result = val[1]
                      result.insert 1, val[0]
                    }
                | block_call tDOT operation2 opt_paren_args
                    {
                      result = new_call val[0], val[2], val[3]
                    }
                | block_call tCOLON2 operation2 opt_paren_args
                    {
                      result = new_call val[0], val[2], val[3]
                    }

     method_call: operation
                    {
                      result = self.lexer.lineno
                    }
                    paren_args
                    {
                      result = new_call nil, val[0].to_sym, val[2]
                    }
                | primary_value tDOT operation2 opt_paren_args
                    {
                      result = new_call val[0], val[2].to_sym, val[3]
                    }
                | primary_value tCOLON2 operation2 paren_args
                    {
                      result = new_call val[0], val[2].to_sym, val[3]
                    }
                | primary_value tCOLON2 operation3
                    {
                      result = new_call val[0], val[2].to_sym
                    }
                | kSUPER paren_args
                    {
                      result = new_super val[1]
                    }
                | kSUPER
                    {
                      result = s(:zsuper)
                    }

     brace_block: tLCURLY
                    {
                      self.env.extend :dynamic
                      result = self.lexer.lineno
                    }
                    opt_block_var
                    {
                      result = nil # self.env.dynamic.keys
                    }
                    compstmt tRCURLY
                    {
                      # REFACTOR
                      args   = val[2]
                      body   = val[4]
                      result = new_iter nil, args, body
                      self.env.unextend
                      result.line = val[1]
                    }
                | kDO
                    {
                      self.env.extend :dynamic
                      result = self.lexer.lineno
                    }
                 opt_block_var
                    {
                      result = nil # self.env.dynamic.keys
                    }
                    compstmt kEND
                    {
                      args = val[2]
                      body = val[4]
                      result = new_iter nil, args, body
                      self.env.unextend
                      result.line = val[1]
                    }

       case_body: kWHEN
                    {
                      result = self.lexer.lineno
                    }
                    when_args then compstmt cases
                    {
                      result = new_when(val[2], val[4])
                      result.line = val[1]
                      result << val[5] if val[5]
                    }

       when_args: args
                | args tCOMMA tSTAR arg_value
                    {
                      result = list_append val[0], s(:splat, val[3])
                    }
                | tSTAR arg_value
                    {
                      result = s(:array, s(:splat, val[1]))
                    }

           cases: opt_else | case_body

      opt_rescue: kRESCUE exc_list exc_var then compstmt opt_rescue
                    {
                      (_, line), klasses, var, _, body, rest = val

                      klasses ||= s(:array)
                      klasses << new_assign(var, s(:gvar, :"$!")) if var
                      klasses.line line

                      result = new_resbody(klasses, body)
                      result << rest if rest # UGH, rewritten above
                    }
                |
                    {
                      result = nil
                    }

        exc_list: arg_value
                    {
                      result = s(:array, val[0])
                    }
                | mrhs
                | none

         exc_var: tASSOC lhs
                    {
                      result = val[1]
                    }
                | none

      opt_ensure: kENSURE compstmt
                    {
                      if (val[1] != nil) then
                        result = val[1]
                      else
                        result = s(:nil)
                      end
                    }
                | none

         literal: numeric { result = s(:lit, val[0]) }
                | symbol  { result = s(:lit, val[0]) }
                | dsym

         strings: string
                    {
                      val[0] = s(:dstr, val[0].value) if val[0].sexp_type == :evstr
                      result = val[0]
                    }

          string: string1
                | string string1
                    {
                      result = literal_concat val[0], val[1]
                    }

         string1: tSTRING_BEG string_contents tSTRING_END
                    {
                      result = val[1]
                    }
                | tSTRING
                    {
                      result = new_string val
                    }

         xstring: tXSTRING_BEG xstring_contents tSTRING_END
                    {
                      result = new_xstring val[1]
                    }

          regexp: tREGEXP_BEG xstring_contents tREGEXP_END
                    {
                      result = new_regexp val
                    }

           words: tWORDS_BEG tSPACE tSTRING_END
                    {
                      result = s(:array)
                    }
                | tWORDS_BEG word_list tSTRING_END
                    {
                      result = val[1]
                    }

       word_list: none
                    {
                      result = new_word_list
                    }
                | word_list word tSPACE
                    {
                      result = val[0] << new_word_list_entry(val)
                    }

            word: string_content
                | word string_content
                    {
                      result = literal_concat val[0], val[1]
                    }

          qwords: tQWORDS_BEG tSPACE tSTRING_END
                    {
                      result = s(:array)
                    }
                | tQWORDS_BEG qword_list tSTRING_END
                    {
                      result = val[1]
                    }

      qword_list: none
                    {
                      result = new_qword_list
                    }
                | qword_list tSTRING_CONTENT tSPACE
                    {
                      result = val[0] << new_qword_list_entry(val)
                    }

 string_contents: none
                    {
                      result = s(:str, "")
                    }
                | string_contents string_content
                    {
                      result = literal_concat(val[0], val[1])
                    }

xstring_contents: none
                    {
                      result = nil
                    }
                | xstring_contents string_content
                    {
                      result = literal_concat(val[0], val[1])
                    }

  string_content: tSTRING_CONTENT
                    {
                      result = new_string val
                    }
                | tSTRING_DVAR
                    {
                      result = lexer.lex_strterm

                      lexer.lex_strterm = nil
                      lexer.lex_state = :expr_beg
                    }
                    string_dvar
                    {
                      lexer.lex_strterm = val[1]
                      result = s(:evstr, val[2])
                    }
                | tSTRING_DBEG
                    {
                      result = [lexer.lex_strterm,
                                lexer.brace_nest,
                                lexer.string_nest, # TODO: remove
                                lexer.cond.store,
                                lexer.cmdarg.store]

                      lexer.lex_strterm = nil
                      lexer.brace_nest  = 0
                      lexer.string_nest = 0

                      lexer.lex_state   = :expr_beg
                    }
                    compstmt tRCURLY
                    {
                      _, memo, stmt, _ = val

                      lex_strterm, brace_nest, string_nest, oldcond, oldcmdarg = memo

                      lexer.lex_strterm = lex_strterm
                      lexer.brace_nest  = brace_nest
                      lexer.string_nest = string_nest

                      lexer.cond.restore oldcond
                      lexer.cmdarg.restore oldcmdarg

                      case stmt
                      when Sexp then
                        case stmt.sexp_type
                        when :str, :dstr, :evstr then
                          result = stmt
                        else
                          result = s(:evstr, stmt)
                        end
                      when nil then
                        result = s(:evstr)
                      else
                        raise "unknown string body: #{stmt.inspect}"
                      end
                    }

     string_dvar: tGVAR { result = s(:gvar, val[0].to_sym) }
                | tIVAR { result = s(:ivar, val[0].to_sym) }
                | tCVAR { result = s(:cvar, val[0].to_sym) }
                | backref

          symbol: tSYMBEG sym
                    {
                      lexer.lex_state = :expr_end
                      result = val[1].to_sym
                    }
                | tSYMBOL
                    {
                      result = val[0].to_sym
                    }

             sym: fname | tIVAR | tGVAR | tCVAR

            dsym: tSYMBEG xstring_contents tSTRING_END
                    {
                      lexer.lex_state = :expr_end
                      result = val[1]

                      yyerror "empty symbol literal" if
                        result.nil? or result.empty?

                      case result.sexp_type
                      when :dstr then
                        result.sexp_type = :dsym
                      when :str then
                        result = s(:lit, result.last.to_sym)
                      else
                        result = s(:dsym, "", result)
                      end
                    }

         numeric: tINTEGER
                | tFLOAT
                | tUMINUS_NUM tINTEGER =tLOWEST
                    {
                      result = -val[1] # TODO: pt_testcase
                    }
                | tUMINUS_NUM tFLOAT   =tLOWEST
                    {
                      result = -val[1] # TODO: pt_testcase
                    }

        variable: tIDENTIFIER
                | tIVAR
                | tGVAR
                | tCONSTANT
                | tCVAR
                | kNIL      { result = s(:nil)   }
                | kSELF     { result = s(:self)  }
                | kTRUE     { result = s(:true)  }
                | kFALSE    { result = s(:false) }
                | k__FILE__ { result = s(:str, self.file) }
                | k__LINE__ { result = s(:lit, lexer.lineno) }

         var_ref: variable
                    {
                      var = val[0]
                      result = Sexp === var ? var : self.gettable(var)
                    }

         var_lhs: variable
                    {
                      result = assignable val[0]
                    }

         backref: tNTH_REF  { result = s(:nth_ref,  val[0]) }
                | tBACK_REF { result = s(:back_ref, val[0]) }

      superclass: term
                    {
                      result = nil
                    }
                | tLT
                    {
                      lexer.lex_state = :expr_beg
                    }
                    expr_value term
                    {
                      result = val[2]
                    }
                | error term
                    {
                      yyerrok
                      result = nil
                    }

       f_arglist: tLPAREN2 f_args opt_nl tRPAREN
                    {
                      result = val[1]
                      lexer.lex_state = :expr_beg
                      self.lexer.command_start = true
                    }
                | f_args term
                    {
                      result = val[0]
                    }

          f_args: f_arg tCOMMA f_optarg tCOMMA f_rest_arg opt_f_block_arg
                    {
                      result = args val
                    }
                | f_arg tCOMMA f_optarg                opt_f_block_arg
                    {
                      result = args val
                    }
                | f_arg tCOMMA              f_rest_arg opt_f_block_arg
                    {
                      result = args val
                    }
                | f_arg                             opt_f_block_arg
                    {
                      result = args val
                    }
                |           f_optarg tCOMMA f_rest_arg opt_f_block_arg
                    {
                      result = args val
                    }
                |           f_optarg                opt_f_block_arg
                    {
                      result = args val
                    }
                |                        f_rest_arg opt_f_block_arg
                    {
                      result = args val
                    }
                |                                       f_block_arg
                    {
                      result = args val
                    }
                |
                    {
                      result = args val
                    }

      f_norm_arg: tCONSTANT
                    {
                      yyerror "formal argument cannot be a constant"
                    }
                | tIVAR
                    {
                      yyerror "formal argument cannot be an instance variable"
                    }
                | tGVAR
                    {
                      yyerror "formal argument cannot be a global variable"
                    }
                | tCVAR
                    {
                      yyerror "formal argument cannot be a class variable"
                    }
                | tIDENTIFIER
                    {
                      identifier = val[0].to_sym
                      self.env[identifier] = :lvar

                      result = val[0]
                    }

           f_arg: f_norm_arg
                    {
                      result = s(:args)
                      result << val[0].to_sym
                    }
                | f_arg tCOMMA f_norm_arg
                    {
                      val[0] << val[2].to_sym
                      result = val[0]
                    }

           f_opt: tIDENTIFIER tEQL arg_value
                    {
                      result = assignable val[0], val[2]
                      # TODO: detect duplicate names
                    }

        f_optarg: f_opt
                    {
                      result = s(:block, val[0])
                    }
                | f_optarg tCOMMA f_opt
                    {
                      result = block_append val[0], val[2]
                    }

    restarg_mark: tSTAR2 | tSTAR

      f_rest_arg: restarg_mark tIDENTIFIER
                    {
                      # TODO: differs from parse.y - needs tests
                      name = val[1].to_sym
                      assignable name
                      result = :"*#{name}"
                    }
                | restarg_mark
                    {
                      name = :"*"
                      self.env[name] = :lvar
                      result = name
                    }

     blkarg_mark: tAMPER2 | tAMPER

     f_block_arg: blkarg_mark tIDENTIFIER
                    {
                      identifier = val[1].to_sym

                      self.env[identifier] = :lvar
                      result = s(:block_arg, identifier.to_sym)
                    }

 opt_f_block_arg: tCOMMA f_block_arg
                    {
                      result = val[1]
                    }
                |
                    {
                      result = nil
                    }

       singleton: var_ref
                | tLPAREN2
                    {
                      lexer.lex_state = :expr_beg
                    }
                    expr opt_nl tRPAREN
                    {
                      result = val[2]
                      yyerror "Can't define single method for literals." if
                        result.sexp_type == :lit
                    }

      assoc_list: none # [!nil]
                    {
                      result = s(:array)
                    }
                | assocs trailer # [!nil]
                    {
                      result = val[0]
                    }
                | args trailer
                    {
                      size = val[0].size
                      if (size % 2 != 1) then # != 1 because of leading :array
                        yyerror "Odd number (#{size}) list for Hash. #{val[0].inspect}"
                      end
                      result = val[0]
                    }

          assocs: assoc
                | assocs tCOMMA assoc
                    {
                      list = val[0].dup
                      more = val[2].sexp_body
                      list.push(*more) unless more.empty?
                      result = list
                    }

           assoc: arg_value tASSOC arg_value
                    {
                      result = s(:array, val[0], val[2])
                    }

       operation: tIDENTIFIER | tCONSTANT | tFID
      operation2: tIDENTIFIER | tCONSTANT | tFID | op
      operation3: tIDENTIFIER | tFID | op
    dot_or_colon: tDOT | tCOLON2
       opt_terms:  | terms
          opt_nl:  | tNL
         trailer:  | tNL | tCOMMA

            term: tSEMI { yyerrok }
                | tNL

           terms: term
                | terms tSEMI { yyerrok }

            none: { result = nil }

end

---- inner

require "ruby_parser/legacy/ruby_lexer"
require "ruby_parser/legacy/ruby_parser_extras"

# :stopdoc:

# Local Variables: **
# racc-token-length-max:14 **
# End: **
