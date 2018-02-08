section \<open> Reactive Conditions \<close>

theory utp_rea_cond
  imports utp_rea_rel
begin

subsection \<open> Healthiness Conditions \<close>
    
definition RC1 :: "('t::trace, '\<alpha>, '\<beta>) rel_rp \<Rightarrow> ('t, '\<alpha>, '\<beta>) rel_rp" where
[upred_defs]: "RC1(P) = (\<not>\<^sub>r (\<not>\<^sub>r P) ;; true\<^sub>r)"
  
definition RC :: "('t::trace, '\<alpha>, '\<beta>) rel_rp \<Rightarrow> ('t, '\<alpha>, '\<beta>) rel_rp" where
[upred_defs]: "RC = RC1 \<circ> RR"
  
lemma RC_intro: "\<lbrakk> P is RR; ((\<not>\<^sub>r (\<not>\<^sub>r P) ;; true\<^sub>r) = P) \<rbrakk> \<Longrightarrow> P is RC"
  by (simp add: Healthy_def RC1_def RC_def)

lemma RC_intro': "\<lbrakk> P is RR; P is RC1 \<rbrakk> \<Longrightarrow> P is RC"
  by (simp add: Healthy_def RC1_def RC_def)

lemma RC1_idem: "RC1(RC1(P)) = RC1(P)"
  by (rel_auto, (blast intro: dual_order.trans)+)
  
lemma RC1_mono: "P \<sqsubseteq> Q \<Longrightarrow> RC1(P) \<sqsubseteq> RC1(Q)"
  by (rel_blast)
      
lemma RC1_prop: 
  assumes "P is RC1"
  shows "(\<not>\<^sub>r P) ;; R1 true = (\<not>\<^sub>r P)"
proof -
  have "(\<not>\<^sub>r P) = (\<not>\<^sub>r (RC1 P))"
    by (simp add: Healthy_if assms)
  also have "... = (\<not>\<^sub>r P) ;; R1 true"
    by (simp add: RC1_def rpred closure)
  finally show ?thesis ..
qed
    
lemma R2_RC: "R2 (RC P) = RC P"
proof -
  have "\<not>\<^sub>r RR P is RR"
    by (metis (no_types) Healthy_Idempotent RR_Idempotent RR_rea_not)
  then show ?thesis
    by (metis (no_types) Healthy_def' R1_R2c_seqr_distribute R2_R2c_def RC1_def RC_def RR_implies_R1 RR_implies_R2c comp_apply rea_not_R2_closed rea_true_R1 rea_true_R2c)
qed

lemma RC_R2_def: "RC = RC1 \<circ> RR"
  by (auto simp add: RC_def fun_eq_iff R1_R2c_commute[THEN sym] R1_R2c_is_R2)
    
lemma RC_implies_R2: "P is RC \<Longrightarrow> P is R2"
  by (metis Healthy_def' R2_RC)
    
lemma RC_ex_ok_wait: "(\<exists> {$ok, $ok\<acute>, $wait, $wait\<acute>} \<bullet> RC P) = RC P"
  by (rel_auto)

subsection \<open> Closure laws \<close>

lemma RC_implies_RR [closure]: 
  assumes "P is RC"
  shows "P is RR"
  by (metis Healthy_def RC_ex_ok_wait RC_implies_R2 RR_def assms)

lemma RC_implies_RC1: "P is RC \<Longrightarrow> P is RC1"
  by (metis Healthy_def RC_R2_def RC_implies_RR comp_eq_dest_lhs)
    
lemma RC1_trace_ext_prefix:
  "out\<alpha> \<sharp> e \<Longrightarrow> RC1(\<not>\<^sub>r $tr ^\<^sub>u e \<le>\<^sub>u $tr\<acute>) = (\<not>\<^sub>r $tr ^\<^sub>u e \<le>\<^sub>u $tr\<acute>)"
  by (rel_auto, blast, metis (no_types, lifting) dual_order.trans)
    
lemma RC1_conj: "RC1(P \<and> Q) = (RC1(P) \<and> RC1(Q))"
  by (rel_blast)
    
lemma conj_RC1_closed [closure]:
  "\<lbrakk> P is RC1; Q is RC1 \<rbrakk> \<Longrightarrow> P \<and> Q is RC1"
  by (simp add: Healthy_def RC1_conj)
    
lemma disj_RC1_closed [closure]:
  assumes "P is RC1" "Q is RC1"
  shows "(P \<or> Q) is RC1"
proof -
  have 1:"RC1(RC1(P) \<or> RC1(Q)) = (RC1(P) \<or> RC1(Q))"
    apply (rel_auto) using dual_order.trans by blast+
  show ?thesis
    by (metis (no_types) Healthy_def 1 assms)
qed

lemma conj_RC_closed [closure]:
  assumes "P is RC" "Q is RC"
  shows "(P \<and> Q) is RC"
  by (metis Healthy_def RC_R2_def RC_implies_RR assms comp_apply conj_RC1_closed conj_RR)
    
lemma rea_true_RC [closure]: "true\<^sub>r is RC"
  by (rel_auto)
    
lemma false_RC [closure]: "false is RC"
  by (rel_auto)
   
lemma disj_RC_closed [closure]: "\<lbrakk> P is RC; Q is RC \<rbrakk> \<Longrightarrow> (P \<or> Q) is RC"
  by (metis Healthy_def RC_R2_def RC_implies_RR comp_apply disj_RC1_closed disj_RR)
  
lemma UINF_mem_RC1_closed [closure]:
  assumes "\<And> i. P i is RC1"
  shows "(\<Sqinter> i\<in>A \<bullet> P i) is RC1"
proof -
  have 1:"RC1(\<Sqinter> i\<in>A \<bullet> RC1(P i)) = (\<Sqinter> i\<in>A \<bullet> RC1(P i))"
    by (rel_auto, meson order.trans)
  show ?thesis
    by (metis (mono_tags, lifting) "1" Healthy_def' UINF_all_cong UINF_alt_def assms)
qed
  
lemma UINF_mem_RC_closed [closure]:
  assumes "\<And> i. P i is RC"
  shows "(\<Sqinter> i\<in>A \<bullet> P i) is RC"
proof -
  have "RC(\<Sqinter> i\<in>A \<bullet> P i) = (RC1 \<circ> RR)(\<Sqinter> i\<in>A \<bullet> P i)"
    by (simp add: RC_def)
  also have "... = RC1(\<Sqinter> i\<in>A \<bullet> RR(P i))"
    by (rel_blast)
  also have "... = RC1(\<Sqinter> i\<in>A \<bullet> RC1(P i))"
    by (simp add: Healthy_if RC_implies_RR RC_implies_RC1 assms)
  also have "... = (\<Sqinter> i\<in>A \<bullet> RC1(P i))"
    by (rel_auto, meson order.trans)
  also have "... = (\<Sqinter> i\<in>A \<bullet> P i)"
    by (simp add: Healthy_if RC_implies_RC1 assms)
  finally show ?thesis
    by (simp add: Healthy_def)
qed

lemma UINF_ind_RC_closed [closure]:
  assumes "\<And> i. P i is RC"
  shows "(\<Sqinter> i \<bullet> P i) is RC"
  by (metis (no_types) UINF_as_Sup_collect' UINF_as_Sup_image UINF_mem_RC_closed assms)
  
lemma USUP_mem_RC1_closed [closure]:
  assumes "\<And> i. P i is RC1" "A \<noteq> {}"
  shows "(\<Squnion> i\<in>A \<bullet> P i) is RC1"
proof -
  have "RC1(\<Squnion> i\<in>A \<bullet> P i) = RC1(\<Squnion> i\<in>A \<bullet> RC1(P i))"
    by (simp add: Healthy_if assms(1))
  also from assms(2) have "... = (\<Squnion> i\<in>A \<bullet> RC1(P i))"
    using dual_order.trans by (rel_blast)
  also have "... = (\<Squnion> i\<in>A \<bullet> P i)"
    by (simp add: Healthy_if assms(1))
  finally show ?thesis
    using Healthy_def by blast
qed

lemma USUP_mem_RC_closed [closure]:
  assumes "\<And> i. P i is RC" "A \<noteq> {}"
  shows "(\<Squnion> i\<in>A \<bullet> P i) is RC"
  by (rule RC_intro', simp_all add: closure assms RC_implies_RC1)  

lemma neg_trace_ext_prefix_RC [closure]: 
  "\<lbrakk> $tr \<sharp> e; $ok \<sharp> e; $wait \<sharp> e; out\<alpha> \<sharp> e \<rbrakk> \<Longrightarrow> \<not>\<^sub>r $tr ^\<^sub>u e \<le>\<^sub>u $tr\<acute> is RC"
  by (rule RC_intro, simp add: closure, metis RC1_def RC1_trace_ext_prefix)

lemma RC1_unrest:
  "\<lbrakk> mwb_lens x; x \<bowtie> tr \<rbrakk> \<Longrightarrow> $x\<acute> \<sharp> RC1(P)"
  by (simp add: RC1_def unrest)
    
lemma RC_unrest_dashed [unrest]:
  "\<lbrakk> P is RC; mwb_lens x; x \<bowtie> tr \<rbrakk> \<Longrightarrow> $x\<acute> \<sharp> P"
  by (metis Healthy_if RC1_unrest RC_implies_RC1)

lemma RC1_RR_closed: "P is RR \<Longrightarrow> RC1(P) is RR"
  by (simp add: RC1_def closure)

end