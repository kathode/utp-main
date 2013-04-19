(******************************************************************************)
(* Project: Unifying Theories of Programming                                  *)
(* File: utp_rel_tac.thy                                                      *)
(* Author: Frank Zeyda, University of York (UK)                               *)
(******************************************************************************)

header {* Proof Tactic for Relations *}

theory utp_rel_tac
imports "../core/utp_pred" "../core/utp_rel" "utp_expr_tac"
begin

text {* Theorem Attribute *}

ML {*
  structure evalr =
    Named_Thms (val name = @{binding evalr} val description = "evalr theorems")
*}

setup evalr.setup

subsection {* Type Synonyms *}

type_synonym 'VALUE RELATION =
  "('VALUE WF_BINDING \<times>
    'VALUE WF_BINDING) set"

subsection {* Relational Model *}

text {*
  We require an arbitrary but fixed binding in our model of relations in order
  to constrain dashed variables which we do not care about. We note that an
  alternative approach is possible that upward closes the relation with respect
  to the values of these variables. In practice, it turns out that a constant
  valuation yields simpler proofs and there is not loss of generality with it.
*}

definition bc :: "'VALUE WF_BINDING" where
"bc = (SOME b . b \<in> UNIV)"

(*
theorem bc_WF_BINDING [closure] :
"bc \<in> WF_BINDING"
apply (simp add: bc_def)
apply (rule_tac P = "\<lambda> b . b \<in> WF_BINDING" in someI_ex)
apply (simp add: WF_BINDING_exists)
done
*)

definition WF_REL_BINDING :: "'VALUE WF_BINDING set" where
"WF_REL_BINDING = {b \<oplus>\<^sub>b bc on DASHED | b . b \<in> UNIV}"

subsection {* Interpretation Function *}

definition BindR ::
  "'VALUE WF_BINDING \<Rightarrow>
   'VALUE WF_BINDING \<times>
   'VALUE WF_BINDING" where
"BindR b = (b \<oplus>\<^sub>b bc on DASHED, (RenameB SS b) \<oplus>\<^sub>b bc on DASHED)"

definition BindP ::
  "'VALUE WF_BINDING \<times>
   'VALUE WF_BINDING \<Rightarrow>
   'VALUE WF_BINDING" where
"BindP = (\<lambda> (rb1, rb2) . rb1 \<oplus>\<^sub>b (RenameB SS rb2) on DASHED)"

definition EvalR ::
  "'VALUE WF_PREDICATE \<Rightarrow>
   'VALUE RELATION" ("\<lbrakk>_\<rbrakk>R") where
"EvalR p = BindR ` (destPRED p)"

definition IEvalR ::
  "'VALUE RELATION \<Rightarrow>
   'VALUE WF_PREDICATE" where
"IEvalR r = mkPRED (BindP ` r)"

subsection {* Auxilary Theorems *}

theorem EvalR_range :
"\<lbrakk>p\<rbrakk>R \<subseteq> WF_REL_BINDING \<times> WF_REL_BINDING"
apply (simp add: EvalR_def)
apply (simp add: image_def)
apply (simp add: BindR_def)
apply (simp add: WF_REL_BINDING_def)
apply (safe)
apply (rule_tac x = "xa" in exI)
apply (simp)
apply (rule_tac x = "RenameB SS xa" in exI)
apply (simp add: closure)
done

theorem WF_REL_BINDING_member1 [simp, intro] :
"\<lbrakk>(rb1, rb2) \<in> \<lbrakk>p\<rbrakk>R\<rbrakk> \<Longrightarrow>
 rb1 \<in> WF_REL_BINDING"
  by (insert EvalR_range[of p], force)

theorem WF_REL_BINDING_member2 [simp, intro] :
"\<lbrakk>(rb1, rb2) \<in> \<lbrakk>p\<rbrakk>R\<rbrakk> \<Longrightarrow>
 rb2 \<in> WF_REL_BINDING"
 by (insert EvalR_range[of p], force)

theorem BindP_inverse :
"BindP (BindR b) = b"
apply (simp add: BindR_def BindP_def)
apply (rule Rep_WF_BINDING_intro)
apply (rule ext)
apply (case_tac "x \<in> DASHED")
apply (simp add: RenameB_def SS_DASHED_member closure)
apply (simp)
done

theorem IEvalR_inverse :
"IEvalR (EvalR p) = p"
apply (simp add: IEvalR_def EvalR_def)
apply (simp add: image_image)
apply (simp add: image_def)
apply (simp add: BindP_inverse)
done

theorem BindR_inject [simp] :
"BindR b1 = BindR b2 \<longleftrightarrow> b1 = b2"
apply (auto simp add: BindR_def)
apply (erule Rep_WF_BINDING_elim)+
apply (rule Rep_WF_BINDING_intro)
apply (auto simp add: override_on_eq)
apply (rule ext)
apply (case_tac "x \<in> DASHED")
-- {* Subgoal 1 *}
apply (drule_tac x = "undash x" in spec)
back
apply (subgoal_tac "undash x \<notin> DASHED")
apply (simp)
apply (simp add: RenameB_def closure)
apply (simp add: urename)
apply (simp add: var_defs)
-- {* Subgoal 2 *}
apply (simp)
done

theorem BindR_COMPOSABLE_BINDINGS :
"\<lbrakk>(rb1, rb3) = BindR b1;
 (rb3, rb2) = BindR b2\<rbrakk> \<Longrightarrow>
 (b1, b2) \<in> COMPOSABLE_BINDINGS"
apply (simp add: BindR_def)
apply (simp add: COMPOSABLE_BINDINGS_def)
apply (auto)
apply (erule Rep_WF_BINDING_elim)+
apply (simp add: override_on_eq RenameB_def)
-- {* Subgoal 1 *}
apply (drule_tac x = "v" in spec)
apply (simp add:urename)
-- {* Subgoal 2 *}
apply (simp add: binding_equiv_def)
apply (simp add: NON_REL_VAR_def)
apply (rule ballI)
apply (simp add: urename)
apply (erule Rep_WF_BINDING_elim)+
apply (simp add:override_on_eq)
apply (drule_tac x = "x" in spec)
apply (simp add:RenameB_def)
apply (metis SS_ident_app)
done

theorem BindR_override :
"\<lbrakk>(rb1, rb3) = BindR b1;
 (rb3, rb2) = BindR b2\<rbrakk> \<Longrightarrow>
 (rb1, rb2) = BindR (b1 \<oplus>\<^sub>b b2 on DASHED)"
apply (simp add: BindR_def)
apply (auto elim!:Rep_WF_BINDING_elim intro!:Rep_WF_BINDING_intro)
apply (simp add: override_on_eq)
apply (simp_all add: RenameB_def closure)
apply (clarify)
apply (drule_tac x = "x" in spec)
apply (auto simp add: urename)
apply (metis SS_UNDASHED_app SS_ident_app UNDASHED_dash_DASHED override_on_def)
done

subsection {* Transfer Theorems *}

theorem EvalR_inj_on :
"inj EvalR"
  by (metis (lifting) IEvalR_inverse inj_onI)

theorem EvalR_simp [evalr] :
"p1 = p2 \<longleftrightarrow> \<lbrakk>p1\<rbrakk>R = \<lbrakk>p2\<rbrakk>R"
apply (rule inj_on_eval_simp [of EvalR UNIV "p1" "p2"])
apply (simp_all add: EvalR_inj_on)
done

theorem EvalR_intro :
"\<lbrakk>p1\<rbrakk>R = \<lbrakk>p2\<rbrakk>R \<Longrightarrow> p1 = p2"
apply (rule inj_on_eval_intro [of EvalR UNIV "p1" "p2"])
apply (simp_all add: EvalR_inj_on)
done

subsection {* Distribution Theorems *}

theorem EvalR_TrueP_explicit :
"\<lbrakk>true\<rbrakk>R = {(b1, b2) | b1 b2 .
   b1 \<in> WF_REL_BINDING \<and>
   b2 \<in> WF_REL_BINDING \<and>
   b1 \<cong> b2 on DASHED \<and>
   b1 \<cong> b2 on NON_REL_VAR}"
apply (simp add: EvalR_def)
apply (simp add: TrueP_def)
apply (simp add: image_def)
apply (simp add: BindR_def WF_REL_BINDING_def)
apply (simp add: binding_equiv_def)
apply (simp add: set_eq_subset)
apply (safe)
-- {* Subgoal 1 *}
apply (rule_tac x = "xa" in exI)
apply (simp)
-- {* Subgoal 2 *}
apply (rule_tac x = "RenameB SS xa" in exI)
apply (simp add: closure)
-- {* Subgoal 3 *}
apply (simp)
-- {* Subgoal 4 *}
apply (simp add: NON_REL_VAR_def)
apply (simp add: RenameB_def closure urename)
-- {* Subgoal 5 *}
apply (rule_tac x = "b \<oplus>\<^sub>b (RenameB SS ba) on DASHED" in exI)
apply (auto elim!:Rep_WF_BINDING_elim intro!:Rep_WF_BINDING_intro)
apply (simp add: override_on_eq)
apply (safe)
apply (simp add: RenameB_def closure)
apply (case_tac "x \<in> UNDASHED")
apply (simp add: SS_simps)
apply (simp add: SS_simps)
apply (drule_tac x = "x" in bspec)
apply (simp add: NON_REL_VAR_def var_defs)
apply (simp)
done

theorem EvalR_TrueP [evalr] :
"\<lbrakk>true\<rbrakk>R = {(x \<oplus>\<^sub>b bc on DASHED, RenameB SS x \<oplus>\<^sub>b bc on DASHED) | x. x \<in> UNIV}"
apply (simp add: EvalR_def)
apply (simp add: TrueP_def)
apply (simp add: image_def BindR_def)
done

theorem EvalR_FalseP [evalr] :
"\<lbrakk>false\<rbrakk>R = {}"
apply (simp add: EvalR_def)
apply (simp add: FalseP_def)
done

theorem EvalR_NotP [evalr] :
"\<lbrakk>\<not>p p\<rbrakk>R = \<lbrakk>true\<rbrakk>R - \<lbrakk>p\<rbrakk>R"
apply (simp add: EvalR_def)
apply (simp add: NotP_def TrueP_def)
apply (auto)
done

theorem EvalR_AndP [evalr] :
"\<lbrakk>p1 \<and>p p2\<rbrakk>R = \<lbrakk>p1\<rbrakk>R \<inter> \<lbrakk>p2\<rbrakk>R"
apply (simp add: EvalR_def)
apply (simp add: AndP_def)
apply (auto)
done

theorem EvalR_OrP [evalr] :
"\<lbrakk>p1 \<or>p p2\<rbrakk>R = \<lbrakk>p1\<rbrakk>R \<union> \<lbrakk>p2\<rbrakk>R"
apply (simp add: EvalR_def)
apply (simp add: OrP_def)
apply (auto)
done

declare ImpliesP_def [evalr]

declare IffP_def [evalr]

theorem EvalR_SkipR [evalr] :
"\<lbrakk>II\<rbrakk>R = Id_on WF_REL_BINDING"
apply (simp add: EvalR_def)
apply (simp add: SkipR_def)
apply (simp add: WF_REL_BINDING_def)
apply (simp add: image_def)
apply (simp add: BindR_def)
apply (simp add: Id_on_def)
apply (simp add: set_eq_iff)
apply (safe)
-- {* Subgoal 1 *}
apply (rename_tac x b)
apply (rule_tac x = "b \<oplus>\<^sub>b bc on DASHED" in exI)
apply (simp add: override_on_eq)
apply (rule conjI)
apply (rule_tac x = "b" in exI)
apply (simp)
apply (simp add: RenameB_def closure)
apply (rule Rep_WF_BINDING_intro)
apply (simp add:override_on_eq o_def)
apply (smt SS_UNDASHED_app SS_ident_app)
-- {* Subgoal 2 *}
apply (rule_tac x = "b \<oplus>\<^sub>b (RenameB SS b) on DASHED" in exI)
apply (simp add: override_on_eq)
apply (auto)
-- {* Subgoal 2.1 *}
apply (subgoal_tac "v \<notin> DASHED")
apply (simp)
apply (simp add: RenameB_def closure urename)
apply (auto) [1]
-- {* Subgoal 2.2 *}
apply (simp add: RenameB_def closure)
apply (rule Rep_WF_BINDING_intro)
apply (auto simp add:override_on_eq urename)
apply (metis (no_types) SS_DASHED_app SS_UNDASHED_app SS_ident_app UNDASHED_dash_DASHED o_def override_on_def undash_dash)
done

lemma EvalP_AssignR [eval]:
  "\<lbrakk>x :=p e\<rbrakk>b = (\<forall> v \<in> UNDASHED. if (v = x) then \<langle>b\<rangle>\<^sub>b v\<acute> = \<lbrakk>e\<rbrakk>\<epsilon>b else \<langle>b\<rangle>\<^sub>b v\<acute> = \<langle>b\<rangle>\<^sub>b v)"
  by (simp add:EvalP_def EvalE_def AssignR.rep_eq)

thm "Id_on_def"

theorem EvalR_AssignR [evalr] :
"\<lbrakk> x \<in> UNDASHED; e \<rhd>\<^sub>e x; UNREST_EXPR DASHED e \<rbrakk> \<Longrightarrow> \<lbrakk>x :=p e\<rbrakk>R = {(b, b(x:=\<^sub>b (\<lbrakk>e\<rbrakk>\<epsilon> b))) | b. b \<in> WF_REL_BINDING}"
apply (simp add: EvalR_def EvalE_def)
apply (simp add: AssignR_def)
apply (simp add: WF_REL_BINDING_def)
apply (simp add: set_eq_iff)
apply (safe)
apply (simp add:BindR_def)
apply (safe)
apply (frule_tac x="x" in bspec)
apply (force)
apply (simp)
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e (xa \<oplus>\<^sub>b bc on DASHED) = \<langle>e\<rangle>\<^sub>e xa")
apply (drule sym)
apply (auto)[1]
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e xa \<rhd> x")
apply (simp)
apply (rule)
apply (simp add:RenameB_rep_eq)
apply (rule)
apply (case_tac "xb \<in> DASHED")
apply (auto)
apply (metis SS_UNDASHED_app)
apply (metis SS_UNDASHED_app SS_ident_app)
apply (metis UNREST_EXPR_def)
apply (simp add:image_def BindR_def)
apply (rule_tac x="ba(x\<acute> :=\<^sub>b \<langle>e\<rangle>\<^sub>e ba) \<oplus>\<^sub>b RenameB SS ba on (DASHED - {x\<acute>})" in exI)
apply (auto)
apply (metis EvalE_compat EvalE_def UNDASHED_dash_DASHED UNREST_EXPR_member binding_override_upd binding_upd_apply var_comp_dash)
apply (subgoal_tac "v\<acute> \<in> DASHED - {x\<acute>}")
apply (simp add:RenameB_rep_eq urename)
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e ba \<rhd> x\<acute>")
apply (metis (lifting) UNDASHED_eq_dash_contra binding_upd_apply)
apply (auto)
apply (metis evar_compat_def var_comp_dash)
apply (metis EvalE_compat EvalE_def UNDASHED_dash_DASHED binding_override_simps(3) binding_override_upd evar_comp_dash)
apply (rule)
apply (simp add:RenameB_rep_eq)
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e (ba \<oplus>\<^sub>b bc on DASHED) = \<langle>e\<rangle>\<^sub>e ba")
apply (simp)
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e ba \<rhd> x")
apply (simp)
apply (rule)
apply (case_tac "xa \<in> DASHED")
apply (simp_all add:urename)
apply (case_tac "xa = x")
apply (simp_all)
apply (metis binding_upd_apply var_comp_dash)
apply (smt Rep_WF_BINDING_rep_eq SS_UNDASHED_app SS_VAR_RENAME_INV SS_ident_app UNDASHED_dash_DASHED VAR_RENAME_INV_app fun_upd_apply member_remove o_apply override_on_apply_in override_on_apply_notin remove_def var_comp_dash)
apply (metis evar_compat_def)
apply (metis UNREST_EXPR_member)
done

theorem SubstP_rel_UNDASHED [evalr] :
"\<lbrakk> x \<in> UNDASHED; e \<rhd>\<^sub>e x; UNREST_EXPR DASHED e \<rbrakk> \<Longrightarrow> \<lbrakk>p[e|x]\<rbrakk>R = {(b1, b2) | b1 b2. (b1(x :=\<^sub>b \<lbrakk>e\<rbrakk>\<epsilon>b1), b2) \<in> \<lbrakk>p\<rbrakk>R}"
apply (auto simp add: EvalR_def EvalE_def BindR_def SubstP_def image_def)
apply (rule_tac x="xa(x :=\<^sub>b \<langle>e\<rangle>\<^sub>e xa)" in bexI)
apply (auto)
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e (xa \<oplus>\<^sub>b bc on DASHED) = \<langle>e\<rangle>\<^sub>e xa")
apply (simp)
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e xa \<rhd> x")
apply (simp)
apply (metis (lifting) evar_compat_def)
apply (metis (lifting) UNREST_EXPR_member)
apply (rule)
apply (rule)
apply (simp add:RenameB_rep_eq)
apply (case_tac "xb \<in> DASHED")
apply (simp_all add:urename)
apply (case_tac "xb \<in> UNDASHED")
apply (simp_all add:urename)
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e xa \<rhd> x")
apply (metis UNDASHED_dash_DASHED UNDASHED_not_DASHED binding_upd_apply evar_compat_def)
apply (metis binding_upd_apply evar_compat_def)
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e xa \<rhd> x")
apply (metis binding_upd_apply)
apply (metis binding_upd_apply evar_compat_def)
apply (rule_tac x="xa \<oplus>\<^sub>b xb on DASHED" in exI)
apply (simp)
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e (xa \<oplus>\<^sub>b xb on DASHED) = \<langle>e\<rangle>\<^sub>e xa")
apply (subgoal_tac "\<langle>e\<rangle>\<^sub>e xa \<rhd> x")
apply (auto)
apply (metis (hide_lams, no_types) binding_override_simps(11) binding_override_simps(2) binding_override_simps(4) binding_override_simps(6) binding_upd_override var_simps(31))
apply (rule)
apply (rule)
apply (simp add:RenameB_rep_eq)
apply (case_tac "xc \<in> UNDASHED")
apply (simp add:SS_simps)
apply (case_tac "xc \<in> DASHED")
apply (simp)
apply (simp add:SS_simps)
apply (metis binding_override_on_eq binding_override_simps(2) binding_upd_override evar_compat_def)
apply (metis evar_compat_def)
apply (metis (lifting) UNREST_EXPR_member)
done





  

theorem RenameB_SS_COMPOSABLE_BINDINGS_1 :
"\<lbrakk>(b1, b2) \<in> COMPOSABLE_BINDINGS\<rbrakk> \<Longrightarrow>
 RenameB SS b1 \<oplus>\<^sub>b bc on DASHED = b2 \<oplus>\<^sub>b bc on DASHED"
apply (rule Rep_WF_BINDING_intro)
apply (simp add: override_on_eq)
apply (simp add: RenameB_def closure)
apply (safe)
apply (auto simp add: COMPOSABLE_BINDINGS_def)
apply (metis (lifting) Compl_iff NON_REL_VAR_def SS_UNDASHED_app SS_ident_app UnE binding_equiv_def)
done

theorem RenameB_SS_COMPOSABLE_BINDINGS_2 :
"\<lbrakk>(b1, b2) \<in> COMPOSABLE_BINDINGS\<rbrakk> \<Longrightarrow>
 RenameB SS (b1 \<oplus>\<^sub>b b2 on DASHED) \<oplus>\<^sub>b bc on DASHED = RenameB SS b2 \<oplus>\<^sub>b bc on DASHED"
apply (rule Rep_WF_BINDING_intro)
apply (simp add: override_on_eq)
apply (simp add: RenameB_def closure)
apply (auto simp add: COMPOSABLE_BINDINGS_def binding_equiv_def NON_REL_VAR_def)
apply (metis Compl_iff Int_iff SS_UNDASHED_app SS_ident_app UNDASHED_dash_DASHED override_on_def)
done

theorems RenameB_SS_COMPOSABLE_BINDINGS =
  RenameB_SS_COMPOSABLE_BINDINGS_1
  RenameB_SS_COMPOSABLE_BINDINGS_2

theorem EvalR_SemiR [evalr] :
"\<lbrakk>p1 ; p2\<rbrakk>R = \<lbrakk>p1\<rbrakk>R O \<lbrakk>p2\<rbrakk>R"
apply (simp add: EvalR_def)
apply (simp add: SemiR_def)
apply (simp add: set_eq_iff)
apply (simp add: relcomp_unfold image_def)
apply (safe)
-- {* Subgoal 1 *}
apply (rename_tac x rb1 rb2 xa b1 b2)
apply (rule_tac x = "(RenameB SS b1) \<oplus>\<^sub>b bc on DASHED" in exI)
apply (rule conjI)
-- {* Subgoal 1.1 *}
apply (rule_tac x = "b1" in bexI)
apply (simp add: BindR_def)
apply (assumption)
-- {* Subgoal 1.2 *}
apply (rule_tac x = "b2" in bexI)
apply (simp add: BindR_def)
apply (simp add: RenameB_SS_COMPOSABLE_BINDINGS)
apply (assumption)
-- {* Subgoal 2 *}
apply (rename_tac x rb1 rb2 rb3 b1 b2)
apply (rule_tac x = "b1 \<oplus>\<^sub>b b2 on DASHED" in exI)
apply (rule conjI)
-- {* Subgoal 2.1 *}
apply (rule_tac x = "b1" in exI)
apply (rule_tac x = "b2" in exI)
apply (simp)
apply (simp add: BindR_COMPOSABLE_BINDINGS)
-- {* Subgoal 2.1 *}
apply (metis BindR_override)
done

declare CondR_def [evalr]

(* The following are useless since quantifications are not supported yet. *)

(*
declare Tautology_def [evalr]
declare Contradiction_def [evalr]
declare Refinement_def [evalr]
*)

subsection {* Proof Tactics *}

text {*
  We note that the proof method is also generic and does not have to be
  recreated for concrete instantiations of the @{term PRED} locale.
*}

ML {*
  fun utp_rel_simpset ctxt =
    (simpset_of ctxt)
      addsimps (evalr.get ctxt)
      addsimps (closure.get ctxt);
*}

ML {*
  fun utp_rel_auto_simpset ctxt =
    (simpset_of ctxt)
      addsimps @{thms "relcomp_unfold"}
*}

ML {*
  fun utp_rel_tac thms ctxt i =
    CHANGED (asm_full_simp_tac (utp_rel_simpset ctxt) i)
*}

ML {*
  fun utp_rel_auto_tac thms ctxt i =
    TRY (asm_full_simp_tac (utp_rel_simpset ctxt) i) THEN
    TRY (asm_full_simp_tac (utp_rel_auto_simpset ctxt) i) THEN
    (auto_tac ctxt)
*}

method_setup utp_rel_tac = {*
  Attrib.thms >>
  (fn thms => fn ctxt =>
    SIMPLE_METHOD' (utp_rel_tac thms ctxt))
*} "proof tactic for relations"

method_setup utp_rel_auto_tac = {*
  Attrib.thms >>
  (fn thms => fn ctxt =>
    SIMPLE_METHOD' (utp_rel_auto_tac thms ctxt))
*} "proof tactic for relations with auto"

subsection {* Algebraic Laws *}

theorem SemiP_FalseP :
"p ; false = false"
  by (utp_rel_auto_tac)

theorem SemiP_OrP_distl :
"p1 ; (p2 \<or>p p3) = (p1 ; p2) \<or>p (p1 ; p3)"
  by (utp_rel_auto_tac)

theorem SemiP_OrP_distr :
"(p1 \<or>p p2) ; p3 = (p1 ; p3) \<or>p (p2 ; p3)"
  by (utp_rel_auto_tac)

theorem SemiP_IffP_comm :
"p1 \<Leftrightarrow>p p2 = p2 \<Leftrightarrow>p p1"
  by (utp_rel_auto_tac)

theorem SemiP_SkipR_left :
"II ; p = p"
  by (utp_rel_auto_tac)

theorem SemiP_SkipR_right :
"p ; II = p"
  by (utp_rel_auto_tac)

theorem SemiR_FalseP_left :
"false ; p = false"
  by (utp_rel_auto_tac)

theorem SemiR_FalseP_right :
"p ; false = false"
  by (utp_rel_auto_tac)

theorem SemiP_assoc :
"p1 ; (p2 ; p3) = (p1 ; p2) ; p3"
  by (utp_rel_auto_tac)

theorem AssignR_SemiP_left:
  "\<lbrakk> x \<in> UNDASHED; e \<rhd>\<^sub>e x; UNREST_EXPR DASHED e \<rbrakk> \<Longrightarrow> x :=p e ; p = p[e|x]"
  apply (utp_rel_auto_tac)
  apply (subgoal_tac "xa(x :=\<^sub>b \<lbrakk>e\<rbrakk>\<epsilon>xa) \<in> WF_REL_BINDING")
  apply (simp add:WF_REL_BINDING_def)
  apply (auto)
  apply (rule_tac x="b(x :=\<^sub>b \<langle>xa\<rangle>\<^sub>b x)" in exI)
  apply (subgoal_tac "b(x :=\<^sub>b \<langle>xa\<rangle>\<^sub>b x) \<oplus>\<^sub>b bc on DASHED = (b \<oplus>\<^sub>b bc on DASHED)(x :=\<^sub>b \<langle>xa\<rangle>\<^sub>b x)")
  apply (drule sym)
  apply (simp_all add:typing)
done

end