(******************************************************************************)
(* Project: Mechanisation of the UTP                                          *)
(* File: utp/theories/utp_subst.thy                                           *)
(* Author: Frank Zeyda, University of York                                    *)
(******************************************************************************)

header {* Substitution *}

theory utp_subst
imports utp_gen_pred utp_eval_tactic
begin

context GEN_PRED
begin

subsection {* Variable Substitutions *}

text {* Substitutions are total bijections and have to respect typing. *}
definition VAR_SUBST_ON :: "'TYPE VAR set \<Rightarrow> (('TYPE VAR \<Rightarrow> 'TYPE VAR) set)" where
"VAR_SUBST_ON a = {ss . bij_split ss a a \<and> (\<forall> v \<in> a . type (ss v) = type v)}"

abbreviation VAR_SUBST :: "('TYPE VAR \<Rightarrow> 'TYPE VAR) set" where
"VAR_SUBST \<equiv> VAR_SUBST_ON UNIV"

text {* mappings is the set of variables which are changed by the substitution *}
definition mappings :: "('a \<Rightarrow> 'a) \<Rightarrow> 'a set" where
"mappings f = {v. f v \<noteq> v} \<union> {v. (inv f) v \<noteq> v}"

lemma mappings_inv: "bij f \<Longrightarrow> mappings (inv f) = mappings f"
  by (auto simp add:mappings_def bij_def inv_inv_eq)

lemma disj_mapping_comm: "\<lbrakk> inj f; inj g; mappings f \<inter> mappings g = {} \<rbrakk> \<Longrightarrow> f \<circ> g = g \<circ> f"
  apply(auto simp add:mappings_def Int_def comp_def)
  apply(rule ext)
  apply(smt inv_f_f)
done

lemma disj_mapping_image[alphabet]: "\<lbrakk> mappings f \<inter> a = {} \<rbrakk> \<Longrightarrow> f ` a = a"
  apply(auto simp add:mappings_def Un_def Int_def image_def)
  apply(metis)+
done

subsection {* Binding Substitution *}

definition SubstB ::
  "('TYPE VAR \<Rightarrow> 'TYPE VAR) \<Rightarrow>
   ('VALUE, 'TYPE) BINDING \<Rightarrow>
   ('VALUE, 'TYPE) BINDING" where
"\<lbrakk>ss \<in> VAR_SUBST; b \<in> WF_BINDING\<rbrakk> \<Longrightarrow>
 SubstB ss b = b \<circ> (inv ss)"

subsection {* Predicate Substitution *}

definition SubstP ::
  " ('VALUE, 'TYPE) ALPHA_PREDICATE \<Rightarrow>
   ('TYPE VAR \<Rightarrow> 'TYPE VAR) \<Rightarrow>
   ('VALUE, 'TYPE) ALPHA_PREDICATE" ("_[_]" [200]) where
"\<lbrakk>ss \<in> VAR_SUBST; p \<in> WF_ALPHA_PREDICATE\<rbrakk> \<Longrightarrow>
 SubstP p ss = (ss ` (\<alpha> p), (SubstB ss) ` (\<beta> p))"

subsection {* Theorems *}

subsubsection {* Variable Substitution *}

theorem VAR_SUBST_inv [closure] :
"ss \<in> VAR_SUBST \<Longrightarrow> (inv ss) \<in> VAR_SUBST"
apply (simp add: VAR_SUBST_ON_def)
apply (safe)
apply (drule_tac x = "inv ss v" in spec)
apply (erule subst)
apply (simp add: surj_f_inv_f bij_def)
done

theorem VAR_SUBST_inv_inv [simp] :
"ss \<in> VAR_SUBST \<Longrightarrow> inv (inv ss) = ss"
apply (simp add: VAR_SUBST_ON_def)
apply (simp add: inv_inv_eq)
done

theorem VAR_SUBST_ss_inv [simp] :
"ss \<in> VAR_SUBST \<Longrightarrow> ss (inv ss x) = x"
apply (simp add: VAR_SUBST_ON_def)
apply (simp add: surj_f_inv_f bij_def)
done

theorem VAR_SUBST_inv_ss [simp] :
"ss \<in> VAR_SUBST \<Longrightarrow> inv ss (ss x) = x"
apply (simp add: VAR_SUBST_ON_def)
apply (simp add: inv_f_f bij_def)
done

theorem VAR_SUBST_inv_comp [simp] :
"ss \<in> VAR_SUBST \<Longrightarrow> inv ss \<circ> ss = id"
apply (simp add: VAR_SUBST_ON_def)
apply (simp add: inv_f_f bij_def)
done

theorem VAR_SUBST_inv_comp' [simp] :
"ss \<in> VAR_SUBST \<Longrightarrow> ss \<circ> inv ss = id"
apply (simp add: VAR_SUBST_ON_def)
apply (simp add: inv_f_f bij_def)
done

theorem VAR_SUBST_inv_dist [simp] :
"\<lbrakk> ss1 \<in> VAR_SUBST; ss2 \<in> VAR_SUBST \<rbrakk> \<Longrightarrow> inv (ss1 \<circ> ss2) = inv ss2 \<circ> inv ss1"
apply(simp add:VAR_SUBST_ON_def bij_def)
apply (auto)
apply (metis inj_on_imp_bij_betw o_inv_distrib)
done

theorem VAR_SUBST_image [simp] :
"\<lbrakk> ss1 \<in> VAR_SUBST; ss2 \<in> VAR_SUBST \<rbrakk> \<Longrightarrow> ss1 ` ss2 ` a = (ss1 \<circ> ss2) ` a"
apply (simp add: image_def)
apply (auto)
done

theorem VAR_SUBST_image_inv [simp] :
"ss \<in> VAR_SUBST \<Longrightarrow> ss ` (inv ss) ` a = a"
apply (simp add: image_def)
apply (auto)
done

theorem VAR_SUBST_inv_image [simp] :
"ss \<in> VAR_SUBST \<Longrightarrow> (inv ss) ` ss ` a = a"
apply (simp add: image_def)
apply (auto)
done

theorem VAR_SUBST_in_image_simp [simp] :
"\<lbrakk>ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow> (ss x \<in> ss ` a) = (x \<in> a)"
apply (simp add: VAR_SUBST_ON_def)
apply (auto simp: bij_def inj_eq)
done

theorem VAR_SUBST_compose [simp,closure]:
"\<lbrakk> ss1 \<in> VAR_SUBST ; ss2 \<in> VAR_SUBST \<rbrakk> \<Longrightarrow> (ss1 \<circ> ss2) \<in> VAR_SUBST"
apply (simp add: VAR_SUBST_ON_def)
apply (auto simp: bij_def)
apply(simp add:inj_comp)
apply(metis UNIV_I image_compose)
done

theorem VAR_SUBST_ON_id [simp,closure]:
"id \<in> VAR_SUBST_ON a"
  by (simp add:VAR_SUBST_ON_def)

theorem VAR_SUBSTS_disj_comm [simp]:
"\<lbrakk> ss1 \<in> VAR_SUBST; ss2 \<in> VAR_SUBST; mappings ss1 \<inter> mappings ss2 = {} \<rbrakk> \<Longrightarrow>
 ss1 \<circ> ss2 = ss2 \<circ> ss1"
  by (auto intro:disj_mapping_comm simp add:VAR_SUBST_ON_def bij_def)

theorem VAR_SUBST_WF_BINDING [simp,binding] :
"\<lbrakk>b \<in> WF_BINDING; ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 b \<circ> ss \<in> WF_BINDING"
apply (simp add: VAR_SUBST_ON_def WF_BINDING_def)
apply (safe)
apply (drule_tac x = "ss v" in spec)
apply (drule_tac x = "v" in spec)
apply (auto)
done

text {* Binding Substitution *}

theorem SubstB_closure [closure] :
"\<lbrakk>ss \<in> VAR_SUBST;
 b \<in> WF_BINDING\<rbrakk> \<Longrightarrow>
 SubstB ss b \<in> WF_BINDING"
  by (auto simp add: SubstB_def binding closure)

theorem SubstsB_inject [simp]:
"\<lbrakk>b1 \<in> WF_BINDING;
 b2 \<in> WF_BINDING;
 ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 (SubstB ss b1 = SubstB ss b2) = (b1 = b2)"
apply (simp add: SubstB_def)
apply (simp add: VAR_SUBST_ON_def)
apply (simp add: bij_comp_inject)
done

theorem SubstB_inv_cancel1 [simp] :
"\<lbrakk>ss \<in> VAR_SUBST;
 b \<in> WF_BINDING\<rbrakk> \<Longrightarrow>
 SubstB (inv ss) (SubstB ss b) = b"
apply (subgoal_tac "SubstB ss b \<in> WF_BINDING")
apply (simp add: SubstB_def closure binding)
apply (rule ext)
apply (simp_all add:closure)
done

theorem SubstB_inv_cancel2 [simp] :
"\<lbrakk>ss \<in> VAR_SUBST;
 b \<in> WF_BINDING\<rbrakk> \<Longrightarrow>
 SubstB ss (SubstB (inv ss) b) = b"
apply (subgoal_tac "SubstB (inv ss) b \<in> WF_BINDING")
apply (simp add: SubstB_def closure binding)
apply (rule ext)
apply (simp_all add:closure)
done

theorem SubstB_compose [simp]:
"\<lbrakk>ss1 \<in> VAR_SUBST; ss2 \<in> VAR_SUBST;
 b \<in> WF_BINDING\<rbrakk> \<Longrightarrow>
 SubstB ss1 (SubstB ss2 b) = SubstB (ss1\<circ>ss2) b"
apply(subgoal_tac "SubstB ss2 b \<in> WF_BINDING")
apply(simp add: SubstB_def)
apply(auto simp add:VAR_SUBST_ON_def o_inv_distrib closure)
done

theorem SubstB_id [simp] :
"\<lbrakk>b \<in> WF_BINDING\<rbrakk> \<Longrightarrow>
 SubstB id b = b"
  by (simp add:SubstB_def)

theorem SubstB_disj_comm [simp] :
"\<lbrakk>ss1 \<in> VAR_SUBST; ss2 \<in> VAR_SUBST;
 b \<in> WF_BINDING; mappings ss1 \<inter> mappings ss2 = {} \<rbrakk> \<Longrightarrow>
 SubstB ss1 (SubstB ss2 b) = SubstB ss2 (SubstB ss1 b)"
  by (metis SubstB_compose VAR_SUBSTS_disj_comm)

lemma SubstB_override1:
"\<lbrakk> ss \<in> VAR_SUBST; a \<in> WF_ALPHABET;
   b \<in> WF_BINDING; b' \<in> WF_BINDING \<rbrakk> \<Longrightarrow>
(SubstB ss b) \<oplus> SubstB ss b' on ss ` a = SubstB ss (b \<oplus> b' on a)"
apply (simp add:SubstB_def)
apply (simp add:override_on_def)
apply(rule ext)
apply(auto)
apply (smt VAR_SUBST_ss_inv imageI)
done


lemma SubstB_override2:
"\<lbrakk> ss \<in> VAR_SUBST; a \<in> WF_ALPHABET;
   b \<in> WF_BINDING; b' \<in> WF_BINDING \<rbrakk> \<Longrightarrow>
SubstB (inv ss) (SubstB ss b \<oplus> b' on ss ` a) = b \<oplus> SubstB (inv ss) b' on a"
apply (simp add:SubstB_def closure binding)
apply (simp add:override_on_def)
apply (rule ext)
apply (auto)
done

lemma SubstB_override3:
"\<lbrakk> ss \<in> VAR_SUBST; a \<in> WF_ALPHABET;
   b \<in> WF_BINDING; b' \<in> WF_BINDING; mappings ss \<inter> a = {} \<rbrakk> \<Longrightarrow>
SubstB ss (b \<oplus> b' on a) = (SubstB ss b) \<oplus> (SubstB ss b') on a"
apply(simp add:SubstB_def closure binding)
apply(simp add:override_on_def)
apply(rule ext)
apply(auto)
apply(simp add:mappings_def Un_def Int_def)
apply(metis VAR_SUBST_ss_inv)
apply(metis VAR_SUBST_in_image_simp VAR_SUBST_ss_inv disj_mapping_image)
done

lemma SubstB_override4:
"\<lbrakk> ss \<in> VAR_SUBST; a \<in> WF_ALPHABET;
   b \<in> WF_BINDING; b' \<in> WF_BINDING; mappings ss \<inter> a = {} \<rbrakk> \<Longrightarrow>
SubstB ss (b \<oplus> b' on a) = SubstB ss (b \<oplus> (SubstB ss b') on a)"
apply(simp add:SubstB_def closure binding)
apply(simp add:override_on_def)
apply(rule ext)
apply(auto)
apply(simp add:mappings_def Un_def Int_def)
apply(metis)
done

lemma override_id_bij:
  assumes "ss \<in> VAR_SUBST_ON a" "a \<in> WF_ALPHABET"
  shows "bij (id \<oplus> ss on a)"
proof -
  have "bij_betw (id \<oplus> ss on a) UNIV UNIV = bij_betw (id \<oplus> ss on a) (a \<union> (-a)) (a \<union> (-a))"
    by (metis sup_compl_top)

  moreover from assms have "bij_betw (id \<oplus> ss on a) (a \<union> (-a)) (a \<union> (-a))"
    by (rule_tac override_bij, auto simp add:VAR_SUBST_ON_def)
  
  ultimately show ?thesis
    by auto
qed    

lemma SubstB_override5: 
  assumes "ss \<in> VAR_SUBST_ON a1" "a1 \<in> WF_ALPHABET" "a2 \<in> WF_ALPHABET"
          "a1 \<inter> a2 = {}" "b \<in> WF_BINDING"
  shows   "(SubstB (id \<oplus> ss on a1) b) \<cong> b on a2"
proof -
  from assms have "bij_betw (id \<oplus> ss on a1) UNIV UNIV"
    by (metis override_id_bij)

  with assms have "id \<oplus> ss on a1 \<in> VAR_SUBST"
    apply(auto simp add:VAR_SUBST_ON_def)
    by (metis id_def override_on_def) 

  moreover from assms have "bij_split ss a1 a1"
    by (simp add:VAR_SUBST_ON_def)

  moreover from assms have "bij_split id a2 a2"
    by simp

  ultimately show ?thesis using assms
    apply(simp add:SubstB_def beta_equiv_def override_inv_id)
    apply(auto)
    apply(simp add:override_on_def)
    apply(force)
  done
qed

lemma SubstB_invol:
"\<lbrakk> ss \<in> VAR_SUBST; b \<in> WF_BINDING; ss \<circ> ss = id \<rbrakk> \<Longrightarrow>
 SubstB ss (SubstB ss b) = b"
  by (metis SubstB_compose SubstB_id)

subsubsection {* Predicate Substitution *}

theorem SubstP_alphabet [alphabet] :
"\<lbrakk>p \<in> WF_ALPHA_PREDICATE;
 ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 \<alpha> p[ss] = ss ` (\<alpha> p)"
  by (simp add: SubstP_def)

lemma [alphabet]: "ss \<in> VAR_SUBST \<Longrightarrow> inv ss ` ss ` a = a"
  by (auto simp add:bij_def)

lemma [alphabet]: "ss \<in> VAR_SUBST \<Longrightarrow> ss ` (a - b) = ss ` a - ss ` b"
  apply (simp add:bij_def VAR_SUBST_ON_def inj_on_def var)
  apply(auto)
done

lemma WF_ALPHABET_image_subst[alphabet]: "\<lbrakk> a \<in> WF_ALPHABET; ss \<in> VAR_SUBST \<rbrakk> \<Longrightarrow> ss ` a \<in> WF_ALPHABET"
  apply(simp only:VAR_SUBST_ON_def)
  apply(auto simp add:bij_def WF_ALPHABET_def)
done

text {* Could the following be useful in other places too? Examine! *}

theorem SubstP_closure_lemma :
"\<lbrakk>ss \<in> VAR_SUBST;
 b1 \<in> WF_BINDING;
 b2 \<in> WF_BINDING\<rbrakk> \<Longrightarrow>
 SubstB ss b1 \<cong> b2 on ss ` a \<longrightarrow> b1 \<cong> SubstB (inv ss) b2 on a"
apply (simp add: beta_equiv_def)
apply (simp add: SubstB_def closure)
done

theorem SubstP_closure [closure] :
"\<lbrakk>p \<in> WF_ALPHA_PREDICATE;
 ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 p[ss] \<in> WF_ALPHA_PREDICATE"
apply (simp add: SubstP_def)
apply (simp only: WF_ALPHA_PREDICATE_def)
apply (safe)
-- {* Subgoal 1 *}
apply (auto simp: WF_ALPHABET_def)
-- {* Subgoal 2 *}
apply (simp add: WF_BINDING_SET_def)
apply (safe)
-- {* Subgoal 2.1 *}
apply (subgoal_tac "xa \<in> WF_BINDING")
apply (simp add:closure)
apply (auto) [1]
-- {* Subgoal 2.2 *}
apply (simp (no_asm_simp) add: image_def)
apply (rule_tac x = "SubstB (inv ss) b2" in bexI)
apply (simp)
apply (drule_tac x = "b1" in bspec)
apply (assumption)
apply (drule_tac x = "SubstB (inv ss) b2" in bspec)
apply (simp add:closure)
apply (subgoal_tac "b1 \<cong> SubstB (inv ss) b2 on \<alpha> p")
apply (simp)
apply (subst SubstP_closure_lemma)
apply (auto)
done

theorem EvalP_SubstP [eval] :
"\<lbrakk>p \<in> WF_ALPHA_PREDICATE;
 ss \<in> VAR_SUBST;
 b \<in> WF_BINDING\<rbrakk> \<Longrightarrow>
 EvalP p[ss] b = EvalP p (SubstB (inv ss) b)"
apply (simp add: EvalP_def closure)
apply (simp add: SubstP_def)
apply (simp add: image_def)
apply (safe)
apply (subgoal_tac "x \<in> WF_BINDING")
apply (simp)
apply (simp add: WF_BINDING_predicate)
apply (rule_tac x = "SubstB (inv ss) b" in bexI)
apply (simp)
apply (assumption)
done

theorem EvalP_SubstsP_SubstB [simp] :
"\<lbrakk>p \<in> WF_ALPHA_PREDICATE;
 b \<in> WF_BINDING;
 ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 EvalP p[ss] (SubstB ss b) = EvalP p b"
apply (simp add: EvalP_def closure)
apply (simp add: SubstP_def)
apply (simp add: image_def)
apply (auto)
apply (subgoal_tac "x \<in> WF_BINDING")
apply (simp)
apply (simp add: WF_BINDING_predicate)
done

subsubsection {* Algebraic Laws *}

theorem SubstP_inverse :
"\<lbrakk>p \<in> WF_ALPHA_PREDICATE;
 ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 p[ss][inv ss] = p"
  by (utp_pred_eq_tac2)

theorem SubstP_compose :
"\<lbrakk>p \<in> WF_ALPHA_PREDICATE;
 ss1 \<in> VAR_SUBST; ss2 \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 p[ss1][ss2] = p[ss2\<circ>ss1]"
  by (utp_pred_eq_tac2)

theorem SubstP_disj_comm:
"\<lbrakk> p \<in> WF_ALPHA_PREDICATE; ss1 \<in> VAR_SUBST; ss2 \<in> VAR_SUBST
; mappings ss1 \<inter> mappings ss2 = {} \<rbrakk> \<Longrightarrow> p[ss1][ss2] = p[ss2][ss1]"
apply (rule eval_intro)
apply (blast intro:closure alpha_closure)
apply (blast intro:closure alpha_closure)
apply (simp add:closure alphabet)
apply (metis VAR_SUBSTS_disj_comm)
apply (simp add:eval closure)
apply (metis VAR_SUBSTS_disj_comm VAR_SUBST_inv_dist)
done

theorem SubstP_id :
"\<lbrakk> p \<in> WF_ALPHA_PREDICATE \<rbrakk> \<Longrightarrow>
 p[id] = p"
  by (utp_pred_eq_tac2)

lemma SubstP_invol:
"\<lbrakk> ss \<in> VAR_SUBST; p \<in> WF_ALPHA_PREDICATE; ss \<circ> ss = id \<rbrakk> \<Longrightarrow>
 p[ss][ss] = p"
  by (metis SubstP_compose SubstP_id)

theorem SubstP_AndP_distr :
"\<lbrakk>p1 \<in> WF_ALPHA_PREDICATE;
 p2 \<in> WF_ALPHA_PREDICATE;
 ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 (p1 \<and>p p2)[ss] = p1[ss] \<and>p p2[ss]"
  by (utp_pred_eq_tac2)

theorem SubstP_OrP_distr :
"\<lbrakk>p1 \<in> WF_ALPHA_PREDICATE;
 p2 \<in> WF_ALPHA_PREDICATE;
 ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 (p1 \<or>p p2)[ss] = p1[ss] \<or>p p2[ss]"
  by (utp_pred_eq_tac2)

theorem SubstP_NotP_distr :
"\<lbrakk>p \<in> WF_ALPHA_PREDICATE;
 ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 (\<not>p p)[ss] = \<not>p p[ss]"
  by (utp_pred_eq_tac2)

theorem ExistsResP_Subst:
"\<lbrakk>p \<in> WF_ALPHA_PREDICATE;
  ss \<in> VAR_SUBST; a \<in> WF_ALPHABET \<rbrakk> \<Longrightarrow>
  p \<ominus>p a = (p[ss] \<ominus>p (ss ` a))[inv ss]"
apply(utp_pred_eq_tac2)
apply(auto)
apply(rule_tac x="SubstB ss b'" in bexI)
apply(auto simp add:SubstB_override1 closure)
apply(rule_tac x="SubstB (inv ss) b'" in bexI)
apply(auto simp add:SubstB_override2 closure)
done

theorem ResP_Subst_disj:
  assumes "p \<in> WF_ALPHA_PREDICATE" "ss \<in> VAR_SUBST" "a \<in> WF_ALPHABET" "mappings ss \<inter> a = {}"
  shows "(p \<ominus>p a)[ss] = p[ss] \<ominus>p a"
apply(insert assms)
apply(simp add:eval closure alphabet)
apply(rule ballI)
apply(rule iffI)
apply(erule bexE)
apply(rule_tac x="SubstB (inv ss) b'" in bexI)
apply (smt SubstB_closure SubstB_inv_cancel2 SubstB_override3 SubstB_override4 VAR_SUBST_inv VAR_SUBST_inv_inv WF_BINDING_override)
apply(simp add:closure)
apply(erule bexE)
apply(rule_tac x="SubstB (inv ss) b'" in bexI)
apply (smt SubstB_closure SubstB_inv_cancel2 SubstB_override2 VAR_SUBST_inv assms(2) disj_mapping_image)
apply(simp add:closure)
done

theorem ExistsResP_Subst_disj:
  assumes "p \<in> WF_ALPHA_PREDICATE" "ss \<in> VAR_SUBST" "a \<in> WF_ALPHABET" "mappings ss \<inter> a = {}"
  shows "(\<exists>-p a . p)[ss] = (\<exists>-p a . p[ss])"
apply(insert assms)
apply(simp add:ExistsResP_def)
apply(simp add:ResP_Subst_disj alphabet closure eval)
done

(*
theorem SubstP_ExistsResP :
"\<lbrakk> a \<in> WF_ALPHABET
 ; p \<in> WF_ALPHA_PREDICATE
 ; ss \<in> VAR_SUBST \<rbrakk> \<Longrightarrow>
 (\<exists>-p a . p)[ss] = (\<exists>-p a . p[ss \<oplus> id on a])"
apply(subgoal_tac "ss \<oplus> id on a \<in> VAR_SUBST")
apply(utp_pred_eq_tac)
apply(auto)
*)


lemma [simp]:"ss \<in> VAR_SUBST \<Longrightarrow> bij ss"
  by (simp add:VAR_SUBST_ON_def)

lemma [simp]:"ss \<in> VAR_SUBST \<Longrightarrow> inj ss"
  by (simp add:VAR_SUBST_ON_def bij_def)

lemma [simp]:"ss \<in> VAR_SUBST \<Longrightarrow> surj ss"
  apply(simp only:VAR_SUBST_ON_def)
  apply(auto simp add:bij_def)
done


theorem Closure_SubstP :
"\<lbrakk>p \<in> WF_ALPHA_PREDICATE;
 ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 [p[ss]] = ([p] :: ('VALUE, 'TYPE) ALPHA_PREDICATE)"
apply(utp_pred_eq_tac2)
apply (auto)
-- {* Can we automate discharging the following residual subgoal? *}
apply (drule_tac x = "SubstB ss x" in bspec)
apply (simp add:closure override_before binding)
apply (simp add: SubstB_def override_before closure binding bij_def)
apply (simp add: SubstB_def override_before closure binding bij_def)
done

subsection {* Proof Experiments *}

text {*
  The following proof illustrate how we use a mixture of algebraic laws and
  the proof strategy for predicates to proof more complex properties. For now
  the strategy alone is not powerful enough to prove the theorem by itself.
*}

declare bij_comp_inject [alphabet]


theorem SubstP_lemma1 :
"\<lbrakk>p1 \<in> WF_ALPHA_PREDICATE;
 p2 \<in> WF_ALPHA_PREDICATE;
 ss \<in> VAR_SUBST\<rbrakk> \<Longrightarrow>
 taut [p1 \<Leftrightarrow>p p2] \<Leftrightarrow>p [p1[ss] \<Leftrightarrow>p p2[ss]]"
apply(auto intro!:eval_intro simp add:closure eval SubstB_def binding)
apply(erule_tac x="b' \<circ> inv ss" in ballE, (simp add:binding closure)+)+
done

lemma VAR_SUBST_ON_subset:
"\<lbrakk> ss \<in> VAR_SUBST_ON a; b \<subseteq> a \<rbrakk> \<Longrightarrow> ss ` b \<subseteq> a"
  by (auto simp add:VAR_SUBST_ON_def image_def bij_betw_def)

lemma VAR_SUBST_ON_override_id[closure]: 
  assumes "a \<in> WF_ALPHABET" "ss \<in> VAR_SUBST_ON a"
  shows "id \<oplus> ss on a \<in> VAR_SUBST"
apply(insert assms)
apply(simp only:VAR_SUBST_ON_def)
apply(auto)
apply (metis assms(2) override_id_bij)
apply(simp add:override_on_def)
done

(*
theorem VAR_SUBST_ON_override:
"\<lbrakk> ss1 \<in> VAR_SUBST_ON a; ss2 \<in> VAR_SUBST_ON b; a \<inter> b = {} \<rbrakk> \<Longrightarrow> ss1 \<oplus> ss2 on b \<in> VAR_SUBST_ON (a \<union> b)"
proof (simp add:VAR_SUBST_ON_def, safe)
  assume assm:"a \<inter> b = {}" "bij_betw ss1 a a" "bij_betw ss2 b b"

  thus "bij_betw (ss1 \<oplus> ss2 on b) (a \<union> b) (a \<union> b)"
  proof -
    from assm have "inj_on (ss1 \<oplus> ss2 on b) (a \<union> b)"
      apply(simp add:inj_on_def bij_betw_def override_on_def)
      apply(metis IntI UnE emptyE imageI)
    done

    moreover
    from assm have "(ss1 \<oplus> ss2 on b) ` a  = a"
      by (metis bij_betw_def inf_commute override_imageL)

    moreover
    from assm have "(ss1 \<oplus> ss2 on b) ` b  = b"
      by (metis bij_betw_def override_imageR)

    ultimately show ?thesis
      by (auto simp add:bij_betw_def)
  qed
next
  fix v
  assume assm: "\<forall>v\<in>a. type (ss1 v) = type v" "\<forall>v\<in>b. type (ss2 v) = type v" "v \<in> a"
  thus "type ((ss1 \<oplus> ss2 on b) v) = type v"
    by (simp add:override_on_def)
next
  fix v
  assume assm: "\<forall>v\<in>a. type (ss1 v) = type v" "\<forall>v\<in>b. type (ss2 v) = type v" "v \<in> b"
  thus "type ((ss1 \<oplus> ss2 on b) v) = type v"
    by (simp add:override_on_def)
next
  assume assm:"a \<inter> b = {}" "bij_betw ss1 (a) (a)" "bij_betw ss2 (b) (b)" "bij_betw ss1 (-a) (-a)" "bij_betw ss2 (-b) (-b)"


  thus "bij_betw (ss1 \<oplus> ss2 on b) (- a \<inter> - b) (- a \<inter> - b)"
    
    apply(simp add: override_on_def bij_betw_def inj_on_def)
    apply(blast)
    apply(auto)
    apply(case_tac "xa \<in> (-a)")
   
    apply(force)
    sorry
qed
*)

lemma [simp]: "ss \<in> VAR_SUBST \<Longrightarrow> ss ` (a \<inter> b) \<subseteq> ss ` a"
  by (unfold VAR_SUBST_ON_def, auto simp add: bij_def)

lemma VAR_SUBST_image_inter[simp]: "ss \<in> VAR_SUBST \<Longrightarrow> ss ` (a \<inter> b) = ss ` a \<inter> ss ` b"
  by (unfold VAR_SUBST_ON_def, auto simp add:bij_def inj_on_def)

theorem ResP_image:
  assumes "p \<in> WF_ALPHA_PREDICATE" "a \<in> WF_ALPHABET" "ss \<in> VAR_SUBST_ON a"
  shows "p \<ominus>p a = p [id \<oplus> ss on a] \<ominus>p (ss ` a)"
apply(insert assms)
apply(utp_pred_eq_tac2)
apply(simp only:VAR_SUBST_ON_def bij_split_def bij_betw_def)
apply(blast)
apply(simp add:eval closure alpha_closure)
apply(rule_tac ballI)
apply(simp add:eval alphabet closure var SubstB_def)
apply(auto)
sorry


lemma [alphabet]: "ss \<in> VAR_SUBST_ON a \<Longrightarrow> bij_betw ss a a"
  by (simp add:VAR_SUBST_ON_def)

theorem ExistsResP_image:
  assumes "p \<in> WF_ALPHA_PREDICATE" "a \<in> WF_ALPHABET" "ss \<in> VAR_SUBST_ON a"
  shows "(\<exists>-p a . p) = (\<exists>-p a . p [id \<oplus> ss on a])"
  apply (insert assms)
  apply (rule EqualityP_intro)
  apply (simp_all add:closure alphabet var)
  apply (auto)[1]
  apply (force simp add:VAR_SUBST_ON_def bij_betw_def)
  apply (auto simp add:closure alphabet var eval)
  apply (auto simp add:SubstB_def closure)

  sorry

(*
proof -
  from assms have "(\<exists>-p a . p) = (\<exists>-p ss ` a . p [id \<oplus> ss on a])"
    by (metis assms ExistsResP_def ResP_image SubstP_closure VAR_SUBST_ON_override_id WF_ALPHABET_image)

  also from assms have "... = (\<exists>-p a . p [id \<oplus> ss on a])"
    by (simp add:VAR_SUBST_ON_def bij_betw_def)

  finally show ?thesis .
qed
*)

theorem ExistsResP_intrude:
  assumes "p \<in> WF_ALPHA_PREDICATE" "a \<in> WF_ALPHABET" "ss \<in> VAR_SUBST"
  shows "(\<exists>-p a . p)[ss] = (\<exists>-p (ss ` a) . p[ss])"
apply(insert assms)
apply(utp_pred_eq_tac2)
apply(auto simp add:SubstB_def closure)
apply(rule_tac x="b' \<circ> inv ss" in bexI)
apply(auto simp add:closure)
done

inductive_set gen_pred :: "(('VALUE, 'TYPE) ALPHA_PREDICATE) set" where
  "a \<in> WF_ALPHABET \<Longrightarrow> true a \<in> gen_pred"  |
  "a \<in> WF_ALPHABET \<Longrightarrow> false a \<in> gen_pred" |
  "\<lbrakk> p \<in> gen_pred; q \<in> gen_pred \<rbrakk> \<Longrightarrow> p \<and>p q \<in> gen_pred" |
  "\<lbrakk> p \<in> gen_pred; q \<in> gen_pred \<rbrakk> \<Longrightarrow> p \<or>p q \<in> gen_pred" |
  "p \<in> gen_pred \<Longrightarrow> \<not>p p \<in> gen_pred"

print_theorems

lemma "gen_pred \<subseteq> WF_ALPHA_PREDICATE"
apply(clarify)
apply(erule gen_pred.induct)
apply(auto)
sorry 

end
end
