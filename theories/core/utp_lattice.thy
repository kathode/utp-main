(******************************************************************************)
(* Project: Unifying Theories of Programming in HOL                           *)
(* File: utp_lattice.thy                                                      *)
(* Author: Simon Foster, University of York (UK)                              *)
(******************************************************************************)

header {* Predicate Lattice *}

theory utp_lattice
imports 
  utp_pred 
  utp_rel 
  utp_unrest 
  "../laws/utp_rel_laws"
  "../tactics/utp_pred_tac" 
  "../tactics/utp_rel_tac"
  "../tactics/utp_xrel_tac"
  "../parser/utp_pred_parser"
begin

instantiation WF_PREDICATE :: (VALUE) lattice
begin

definition sup_WF_PREDICATE :: "'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE" where
"sup_WF_PREDICATE = OrP"

definition inf_WF_PREDICATE :: "'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE" where
"inf_WF_PREDICATE = AndP"

instance
  apply (intro_classes)
  apply (simp_all add: sup_WF_PREDICATE_def inf_WF_PREDICATE_def less_eq_WF_PREDICATE_def less_WF_PREDICATE_def)
  apply (utp_pred_auto_tac)+
done
end

declare sup_WF_PREDICATE_def [eval,evalr,evalrx]
declare inf_WF_PREDICATE_def [eval,evalr,evalrx]

notation
  bot ("\<top>") and
  top ("\<bottom>")

syntax
  "_upred_inf"      :: "upred \<Rightarrow> upred \<Rightarrow> upred" (infixl "\<sqinter>" 65)
  "_upred_sup"      :: "upred \<Rightarrow> upred \<Rightarrow> upred" (infixl "\<squnion>" 70)
  "_upred_Inf"      :: "upred \<Rightarrow> upred \<Rightarrow> upred" ("\<Sqinter>_" [900] 900)
  "_upred_Sup"      :: "upred \<Rightarrow> upred \<Rightarrow> upred" ("\<Squnion>_" [900] 900)

translations
  "_upred_inf p q"  == "CONST sup p q"
  "_upred_sup p q"  == "CONST inf p q"
  "_upred_Inf p q"  == "CONST Sup p q"
  "_upred_Sup p q"  == "CONST Inf p q"

instantiation WF_PREDICATE :: (VALUE) bounded_lattice
begin

definition top_WF_PREDICATE :: "'a WF_PREDICATE" where
"top_WF_PREDICATE = TrueP"

definition bot_WF_PREDICATE :: "'a WF_PREDICATE" where
"bot_WF_PREDICATE = FalseP"

instance proof

  fix a :: "'a WF_PREDICATE"
  show "bot \<le> a"
    apply (simp add:bot_WF_PREDICATE_def less_eq_WF_PREDICATE_def)
    apply (utp_pred_auto_tac)
  done

  show "a \<le> top_class.top"
    apply (simp add:top_WF_PREDICATE_def less_eq_WF_PREDICATE_def)
    apply (utp_pred_auto_tac)
  done
qed
end

declare bot_WF_PREDICATE_def [eval,evalr,evalrx]
declare top_WF_PREDICATE_def [eval,evalr,evalrx]

instantiation WF_PREDICATE :: (VALUE) Inf
begin

definition Inf_WF_PREDICATE ::
  "'VALUE WF_PREDICATE set \<Rightarrow>
   'VALUE WF_PREDICATE" where
"Inf_WF_PREDICATE ps = (if ps = {} then top else mkPRED (\<Inter> (destPRED ` ps)))"

instance ..
end

instantiation WF_PREDICATE :: (VALUE) Sup
begin

definition Sup_WF_PREDICATE ::
  "'VALUE WF_PREDICATE set \<Rightarrow>
   'VALUE WF_PREDICATE" where
"Sup_WF_PREDICATE ps = (if ps = {} then bot else mkPRED (\<Union> (destPRED ` ps)))"

instance ..
end

lemma EvalP_Inf [eval] :
"\<lbrakk>\<Sqinter> ps\<rbrakk>b = (\<exists> p \<in> ps . \<lbrakk>p\<rbrakk>b)"
apply (simp add: EvalP_def closure)
apply (simp add: Sup_WF_PREDICATE_def)
apply (clarify)
apply (simp add: bot_WF_PREDICATE_def FalseP_def)
done

lemma EvalP_Sup [eval] :
"\<lbrakk>\<Squnion> ps\<rbrakk>b = (\<forall> p \<in> ps . \<lbrakk>p\<rbrakk>b)"
apply (simp add: EvalP_def closure)
apply (simp add: Inf_WF_PREDICATE_def)
apply (clarify)
apply (simp add: top_WF_PREDICATE_def TrueP_def)
done

instantiation WF_PREDICATE :: (VALUE) complete_lattice
begin

instance
  apply (intro_classes)
  apply (simp_all add:less_eq_WF_PREDICATE_def)
  apply (utp_pred_auto_tac)+
done
end

declare INF_def [eval]
declare SUP_def [eval]

instantiation WF_PREDICATE :: (VALUE) complete_distrib_lattice
begin

instance
  apply (intro_classes)
  apply (utp_pred_auto_tac)+
done
end

instantiation WF_PREDICATE :: (VALUE) boolean_algebra
begin

definition uminus_WF_PREDICATE :: "'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE" where
"uminus_WF_PREDICATE p = \<not>\<^sub>p p"

definition minus_WF_PREDICATE :: "'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE" where
"minus_WF_PREDICATE p q = (p \<and>\<^sub>p \<not>\<^sub>p q)"

instance 
  apply (intro_classes)
  apply (simp_all add: uminus_WF_PREDICATE_def minus_WF_PREDICATE_def inf_WF_PREDICATE_def sup_WF_PREDICATE_def bot_WF_PREDICATE_def top_WF_PREDICATE_def)
  apply (utp_pred_tac)+
done
end

theorem Lattice_L1:
  fixes P :: "'VALUE WF_PREDICATE"
  shows "P \<sqsubseteq> \<Sqinter> S \<longleftrightarrow> (\<forall> X\<in>S. P \<sqsubseteq> X)"
  by (metis Sup_le_iff)

theorem Lattice_L1A:
  fixes X :: "'VALUE WF_PREDICATE"
  shows "X \<in> S \<Longrightarrow> \<Sqinter> S \<sqsubseteq> X"
  by (metis Sup_upper)

theorem Lattice_L1B:
  fixes P :: "'VALUE WF_PREDICATE"
  shows "\<forall> X \<in> S. P \<sqsubseteq> X \<Longrightarrow> P \<sqsubseteq> \<Sqinter> S"
  by (metis Lattice_L1)

theorem Lattice_L2:
  fixes Q :: "'VALUE WF_PREDICATE"
  shows "(\<Squnion> S) \<sqinter> Q = \<Squnion> { P \<sqinter> Q | P. P \<in> S}"
proof -

  have "(\<Squnion> S) \<sqinter> Q = Q \<sqinter> (\<Squnion> S)"
    by (metis sup.commute)

  also have "... = (INF P:S. P \<sqinter> Q)"
    by (metis Inf_sup sup_commute)

  also have "... = \<Squnion> { P \<sqinter> Q | P. P \<in> S}"
    apply (simp add:INF_def image_def)
    apply (subgoal_tac "{y. \<exists>x\<in>S. y = x \<sqinter> Q} = {P \<sqinter> Q |P. P \<in> S}")
    apply (simp)
    apply (auto)
  done

  ultimately show ?thesis by simp

qed
  
theorem Lattice_L3:
  fixes Q :: "'VALUE WF_PREDICATE"
  shows "(\<Sqinter> S) \<squnion> Q = \<Sqinter>{ P \<squnion> Q | P. P \<in> S}"
proof -

  have "(\<Sqinter> S) \<squnion> Q = (SUP P:S. P \<squnion> Q)"
    by (metis Sup_inf)

  also have "... = \<Sqinter> { P \<squnion> Q | P. P \<in> S}"
    apply (simp add:SUP_def image_def)
    apply (subgoal_tac "{y. \<exists>x\<in>S. y = x \<squnion> Q} = {P \<squnion> Q |P. P \<in> S}")
    apply (simp)
    apply (auto)
  done

  ultimately show ?thesis by simp

qed

lemma EvalR_SupP [evalr]:
  "\<lbrakk>\<Sqinter> ps\<rbrakk>R = \<Union> {\<lbrakk>p\<rbrakk>R | p . p \<in> ps}"
  by (auto simp add:EvalR_def Sup_WF_PREDICATE_def bot_WF_PREDICATE_def FalseP_def)

lemma EvalRR_SupP [evalrr]:
  "\<lbrakk>\<Sqinter> ps\<rbrakk>\<R> = \<Union> {\<lbrakk>p\<rbrakk>\<R> | p . p \<in> ps}"
  by (auto simp add:evalr MkRel_def)

lemma EvalRX_SupP [evalrx]:
  "\<lbrakk>\<Sqinter> ps\<rbrakk>RX = \<Union> {\<lbrakk>p\<rbrakk>RX | p . p \<in> ps}"
  by (auto simp add:EvalRX_def Sup_WF_PREDICATE_def bot_WF_PREDICATE_def FalseP_def)

lemma image_Inter: "\<lbrakk> inj_on f (\<Union>S); S \<noteq> {} \<rbrakk> \<Longrightarrow> f ` \<Inter>S = (\<Inter>x\<in>S. f ` x)"
  apply (auto simp add:image_def)
  apply (smt InterI UnionI inj_on_contraD)
done

lemma EvalR_InfP [evalr]:
  "ps \<noteq> {} \<Longrightarrow> \<lbrakk>\<Squnion> ps\<rbrakk>R = \<Inter> {\<lbrakk>p\<rbrakk>R | p . p \<in> ps}"
  apply (simp add: Inf_WF_PREDICATE_def EvalR_def)
  apply (simp add:EvalR_def Inf_WF_PREDICATE_def top_WF_PREDICATE_def TrueP_def)
  apply (auto)
  apply (smt BindR_inject EvalR_def INT_I image_iff)
done

lemma EvalRR_InfP [evalrr]:
  "ps \<noteq> {} \<Longrightarrow> \<lbrakk>\<Squnion> ps\<rbrakk>\<R> = \<Inter> {\<lbrakk>p\<rbrakk>\<R> | p . p \<in> ps}"
  apply (simp add:evalr MkRel_def)
  apply (rule trans)
  apply (rule image_Inter)
  apply (rule subset_inj_on)
  apply (rule map_pair_inj_on)
  apply (rule MkRelB_inj)
  apply (rule MkRelB_inj)
  apply (smt EvalR_range Sup_le_iff mem_Collect_eq)
  apply (auto)
done

lemma rel_Sup_comp_distl: "(\<Union> S) O Q = \<Union>{ P O Q | P. P \<in> S}"
  by (auto)

lemma rel_Sup_comp_distr: "P O (\<Union> S) = \<Union>{ P O Q | Q. Q \<in> S}"
  by (auto)

theorem Lattice_L4:
  fixes Q :: "'VALUE WF_PREDICATE"
  shows "(\<Sqinter> S) ; Q = \<Sqinter>{ P ; Q | P. P \<in> S}"
  apply (utp_rel_tac)
  apply (auto simp add:rel_Sup_comp_distl)
  apply (metis (hide_lams, no_types) EvalR_SemiR relcomp.intros)
done

theorem Lattice_L5:
  fixes P :: "'VALUE WF_PREDICATE"
  shows "P ; (\<Sqinter> S) = \<Sqinter>{ P ; Q | Q. Q \<in> S}"
  apply (utp_rel_tac)
  apply (simp add:rel_Sup_comp_distr)
  apply (auto)
  apply (metis (hide_lams, no_types) EvalR_SemiR relcomp.intros)
done

lemma Inter_inter_dist: "S \<noteq> {} \<Longrightarrow> (\<Inter> S) \<inter> P = \<Inter> {s \<inter> P | s. s \<in> S}"
  by (auto)

lemma "S \<noteq> {} \<Longrightarrow> (\<Squnion> S) \<and>\<^sub>p P = (\<Squnion> {s \<and>\<^sub>p P | s. s \<in> S})"
  oops

subsection {* @{term UNREST} Theorems *}

lemma UNREST_BotP [unrest]: "UNREST vs \<bottom>"
  by (simp add:top_WF_PREDICATE_def unrest)

lemma UNREST_TopP [unrest]: "UNREST vs \<top>"
  by (simp add:bot_WF_PREDICATE_def unrest)

lemma UNREST_sup :
"\<lbrakk>UNREST vs p1;
 UNREST vs p2\<rbrakk> \<Longrightarrow>
 UNREST vs (p1 \<squnion> p2)"
  by (simp add: inf_WF_PREDICATE_def UNREST_AndP)

lemma UNREST_inf [unrest]:
"\<lbrakk>UNREST vs p1;
 UNREST vs p2\<rbrakk> \<Longrightarrow>
 UNREST vs (p1 \<sqinter> p2)"
  by (auto simp add: sup_WF_PREDICATE_def UNREST_OrP)

lemma UNREST_Sup [unrest]:
"\<forall> p \<in> ps. UNREST vs p \<Longrightarrow> UNREST vs (\<Squnion> ps)"
  apply (simp add: Inf_WF_PREDICATE_def UNREST_BotP)
  apply (simp add: UNREST_def)
done

lemma UNREST_Inf [unrest]:
"\<forall> p \<in> ps. UNREST vs p \<Longrightarrow> UNREST vs (\<Sqinter> ps)"
  apply (simp add: Sup_WF_PREDICATE_def UNREST_TopP)
  apply (auto simp add: UNREST_def)
done

lemma Sup_rel_closure [closure]:
  "\<forall> p \<in> ps. p \<in> WF_RELATION \<Longrightarrow> \<Squnion> ps \<in> WF_RELATION"
  apply (simp add:WF_RELATION_def)
  apply (auto intro:unrest)
done

lemma Inf_rel_closure [closure]:
  "\<forall> p \<in> ps. p \<in> WF_RELATION \<Longrightarrow> \<Sqinter> ps \<in> WF_RELATION"
  apply (simp add:WF_RELATION_def)
  apply (auto intro:unrest)
done

instantiation WF_PREDICATE :: (VALUE) monoid_mult
begin

definition 
  times_WF_PREDICATE :: "'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE" where
  "P * Q = P ; Q"

definition one_WF_PREDICATE :: "'a WF_PREDICATE" where
"1 = II"

instance 
  apply (intro_classes)
  apply (simp_all add:times_WF_PREDICATE_def one_WF_PREDICATE_def SemiR_assoc)
done
end

declare times_WF_PREDICATE_def [eval, evalr, evalrr, evalrx]
declare one_WF_PREDICATE_def [eval, evalr, evalrr, evalrx]

instantiation WF_PREDICATE :: (VALUE) comm_monoid_add
begin

definition 
  plus_WF_PREDICATE :: "'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE \<Rightarrow> 'a WF_PREDICATE" where
  "plus_WF_PREDICATE p q = p \<or>\<^sub>p q"

definition 
  zero_WF_PREDICATE :: "'a WF_PREDICATE" where
  "0 = FalseP"

instance 
  apply (intro_classes)
  apply (simp_all add: plus_WF_PREDICATE_def zero_WF_PREDICATE_def)
  apply (utp_pred_auto_tac)+
done
end

declare plus_WF_PREDICATE_def [eval, evalr, evalrr, evalrx]
declare zero_WF_PREDICATE_def [eval, evalr, evalrr, evalrx]

instantiation WF_PREDICATE :: (VALUE) semiring_1
begin

instance
  apply (intro_classes)
  apply (simp_all add:plus_WF_PREDICATE_def times_WF_PREDICATE_def 
                      zero_WF_PREDICATE_def one_WF_PREDICATE_def)
  apply (utp_rel_tac)+
done
end

theorem SkipR_SupP_def: 
  "II = \<Squnion> { $\<^sub>ex\<acute> ==\<^sub>p $\<^sub>ex | x. x \<in> UNDASHED}"
  apply (auto intro!:destPRED_intro simp add:SkipR_def Inf_WF_PREDICATE_def UNDASHED_nempty EqualP_def VarE.rep_eq)
  apply (metis (lifting, full_types) LiftP.rep_eq destPRED_inverse mem_Collect_eq)
done

theorem SkipRA_SupP_def: 
  "\<lbrakk> vs \<subseteq> REL_VAR; HOMOGENEOUS vs \<rbrakk> \<Longrightarrow> 
     II\<^bsub>vs\<^esub> = \<Squnion> { $\<^sub>ex\<acute> ==\<^sub>p $\<^sub>ex | x. x \<in> in vs}"
  apply (auto intro!:destPRED_intro simp add:SkipRA_rep_eq_alt Inf_WF_PREDICATE_def UNDASHED_nempty EqualP_def VarE.rep_eq top_WF_PREDICATE_def TrueP_def)
  apply (metis (lifting, full_types) LiftP.rep_eq destPRED_inverse mem_Collect_eq)
done

subsection {* Disjunctive / Monotonicity properties *}

lemma OrP_disjunctive2:
  "disjunctive2 (op \<or>\<^sub>p)"
  apply (simp add:disjunctive2_def)
  apply (utp_pred_auto_tac)
done

lemma OrP_mono2:
  "mono2 (op \<or>\<^sub>p)"
  by (metis OrP_disjunctive2 disjunctive2_mono2)

lemma AndP_disjunctive2:
  "disjunctive2 (op \<and>\<^sub>p)"
  apply (simp add:disjunctive2_def)
  apply (utp_pred_auto_tac)
done

lemma AndP_mono2:
  "mono2 (op \<and>\<^sub>p)"
  by (metis AndP_disjunctive2 disjunctive2_mono2)

lemma SemiR_disjunctive2:
  "disjunctive2 (op ;)"
  apply (simp add:disjunctive2_def)
  apply (utp_rel_auto_tac)
done

lemma SemiR_mono2:
  "mono2 (op ;)"
  by (metis SemiR_disjunctive2 disjunctive2_mono2)

end