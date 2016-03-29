section {* Functional programming lenses *}

theory Lenses
imports Main
begin

record ('a, '\<alpha>) lens =
  lens_get :: "'\<alpha> \<Rightarrow> 'a" ("get\<index>")
  lens_put :: "'\<alpha> \<Rightarrow> 'a \<Rightarrow> '\<alpha>" ("put\<index>")

definition lens_create :: "('a, '\<alpha>) lens \<Rightarrow> 'a \<Rightarrow> '\<alpha>" ("create\<index>") where
"lens_create x v = lens_put x undefined v"

definition effectual :: "('a, '\<alpha>) lens \<Rightarrow> bool" where
"effectual x = (\<forall> \<sigma>. \<exists> v. lens_put x \<sigma> v \<noteq> \<sigma>)"

abbreviation "ineffectual x \<equiv> (\<not> effectual x)"

subsection {* Lens composition, product, unit, and identity *}

definition lens_comp :: "('a, 'b) lens \<Rightarrow> ('b, 'c) lens \<Rightarrow> ('a, 'c) lens" (infixr ";\<^sub>l" 80) where
"lens_comp y x = \<lparr> lens_get = lens_get y \<circ> lens_get x, lens_put = (\<lambda> \<sigma> v. lens_put x \<sigma> (lens_put y (lens_get x \<sigma>) v)) \<rparr>"

definition prod_lens :: "('a, '\<alpha>) lens \<Rightarrow> ('b, '\<alpha>) lens \<Rightarrow> ('a \<times> 'b, '\<alpha>) lens" (infixr "\<times>\<^sub>l" 75) where
"prod_lens x y = \<lparr> lens_get = (\<lambda> \<sigma>. (lens_get x \<sigma>, lens_get y \<sigma>))
                 , lens_put = (\<lambda> \<sigma> (u, v). lens_put x (lens_put y \<sigma> v) u) \<rparr>"

definition fst_lens :: "('a, 'a \<times> 'b) lens" ("fst\<^sub>l") where
"fst_lens = \<lparr> lens_get = fst, lens_put = (\<lambda> (\<sigma>, \<rho>) u. (u, \<rho>)) \<rparr>"

definition snd_lens :: "('b, 'a \<times> 'b) lens" ("snd\<^sub>l") where
"snd_lens = \<lparr> lens_get = snd, lens_put = (\<lambda> (\<sigma>, \<rho>) u. (\<sigma>, u)) \<rparr>"

definition unit_lens :: "(unit, '\<alpha>) lens" ("0\<^sub>l") where
"unit_lens = \<lparr> lens_get = (\<lambda> _. ()), lens_put = (\<lambda> \<sigma> x. \<sigma>) \<rparr>"

definition lens_restrict :: "('a, 'c) lens \<Rightarrow> ('b, 'c) lens \<Rightarrow> ('a, 'b) lens" (infixr "\\\<^sub>l" 90) where
"lens_restrict x y = \<lparr> lens_get = \<lambda> \<sigma>. get\<^bsub>x\<^esub> (create\<^bsub>y\<^esub> \<sigma>), lens_put = \<lambda> \<sigma> v. get\<^bsub>y\<^esub> (put\<^bsub>x\<^esub> (create\<^bsub>y\<^esub> \<sigma>) v) \<rparr>"

lemma ineffectual_unit_lens: "ineffectual 0\<^sub>l"
  by (auto simp add: effectual_def unit_lens_def)

definition id_lens :: "('\<alpha>, '\<alpha>) lens" ("I\<^sub>l") where
"id_lens = \<lparr> lens_get = id, lens_put = (\<lambda> _. id) \<rparr>"

lemma lens_comp_assoc: "(x ;\<^sub>l y) ;\<^sub>l z = x ;\<^sub>l (y ;\<^sub>l z)"
  by (auto simp add: lens_comp_def)

lemma lens_comp_left_id [simp]: "I\<^sub>l ;\<^sub>l x = x"
  by (simp add: id_lens_def lens_comp_def)

lemma lens_comp_right_id [simp]: "x ;\<^sub>l I\<^sub>l = x"
  by (simp add: id_lens_def lens_comp_def)

subsection {* Weak lenses *}

locale weak_lens =
  fixes x :: "('a, '\<alpha>) lens" (structure)
  assumes put_get: "get (put \<sigma> v) = v"
begin

  lemma create_get: "get (create v) = v"
    by (simp add: lens_create_def put_get)

  lemma create_inj: "inj create"
    by (metis create_get injI)

  definition update :: "('a \<Rightarrow> 'a) \<Rightarrow> ('\<alpha> \<Rightarrow> '\<alpha>)" where
  "update f \<sigma> = put \<sigma> (f (get \<sigma>))"

  lemma get_update: "get (update f \<sigma>) = f (get \<sigma>)"
    by (simp add: put_get update_def)

  lemma view_determination: "put \<sigma> u = put \<rho> v \<Longrightarrow> u = v"
    by (metis put_get)

  lemma put_inj: "inj (put \<sigma>)"
    by (simp add: injI view_determination)

end

declare weak_lens.put_get [simp]
declare weak_lens.create_get [simp]

lemma ineffectual_const_get:
  "\<lbrakk> weak_lens x; ineffectual x \<rbrakk> \<Longrightarrow> \<exists> v.  \<forall> \<sigma>. lens_get x \<sigma> = v"
  apply (auto simp add: effectual_def)
  apply (metis weak_lens.put_get)
done

subsection {* Well-behaved lenses *}

locale wb_lens = weak_lens +
  assumes get_put: "put \<sigma> (get \<sigma>) = \<sigma>"
begin

  lemma put_twice: "put (put \<sigma> v) v = put \<sigma> v"
    by (metis get_put put_get)

  lemma put_surjectivity: "\<exists> \<rho> v. put \<rho> v = \<sigma>"
    using get_put by blast

  lemma source_stability: "\<exists> v. put \<sigma> v = \<sigma>"
    using get_put by auto

end

declare wb_lens.get_put [simp]

lemma wb_lens_weak [simp]: "wb_lens x \<Longrightarrow> weak_lens x"
  by (simp_all add: wb_lens_def) 

lemma id_wb_lens: "wb_lens id_lens"
  by (unfold_locales, simp_all add: id_lens_def)

lemma unit_wb_lens: "wb_lens unit_lens"
  by (unfold_locales, simp_all add: unit_lens_def)

lemma comp_wb_lens: "\<lbrakk> wb_lens x; wb_lens y \<rbrakk> \<Longrightarrow> wb_lens (x ;\<^sub>l y)"
  by (unfold_locales, simp_all add: lens_comp_def)

subsection {* Lens independence *}

definition lens_indep :: "('a, '\<alpha>) lens \<Rightarrow> ('b, '\<alpha>) lens \<Rightarrow> bool" (infix "\<bowtie>" 50) where
"x \<bowtie> y \<longleftrightarrow> (\<forall> u v \<sigma>. lens_put x (lens_put y \<sigma> v) u = lens_put y (lens_put x \<sigma> u) v
                    \<and> lens_get x (lens_put y \<sigma> v) = lens_get x \<sigma>
                    \<and> lens_get y (lens_put x \<sigma> u) = lens_get y \<sigma>)"

lemma lens_indepI:
  "\<lbrakk> \<And> u v \<sigma>. lens_put x (lens_put y \<sigma> v) u = lens_put y (lens_put x \<sigma> u) v;
     \<And> v \<sigma>. lens_get x (lens_put y \<sigma> v) = lens_get x \<sigma>;
     \<And> u \<sigma>. lens_get y (lens_put x \<sigma> u) = lens_get y \<sigma> \<rbrakk> \<Longrightarrow> x \<bowtie> y"
  by (simp add: lens_indep_def)

text {* Independence is irreflexive for effectual lenses *}

lemma lens_indep_sym:  "x \<bowtie> y \<Longrightarrow> y \<bowtie> x"
  by (metis lens_indep_def)

lemma lens_indep_comm:
  "x \<bowtie> y \<Longrightarrow> lens_put x (lens_put y \<sigma> v) u = lens_put y (lens_put x \<sigma> u) v"
  by (simp add: lens_indep_def)

lemma lens_indep_get [simp]:
  assumes "x \<bowtie> y"
  shows "lens_get x (lens_put y \<sigma> v) = lens_get x \<sigma>"
  using assms lens_indep_def by fastforce

lemma prod_wb_lens:
  assumes "wb_lens x" "wb_lens y" "x \<bowtie> y"
  shows "wb_lens (x \<times>\<^sub>l y)"
  using assms
  apply (unfold_locales, simp_all add: prod_lens_def)
  apply (simp add: lens_indep_sym prod.case_eq_if)
done

lemma fst_lens_prod:
  "wb_lens y \<Longrightarrow> fst\<^sub>l ;\<^sub>l (x \<times>\<^sub>l y) = x"
  by (simp add: fst_lens_def prod_lens_def lens_comp_def comp_def)

lemma fst_snd_lens_indep:
  "fst\<^sub>l \<bowtie> snd\<^sub>l"
  by (simp add: lens_indep_def fst_lens_def snd_lens_def)

text {* The second law requires independence as we have to apply x first, before y *}

lemma snd_lens_prod:
  "\<lbrakk> wb_lens x; x \<bowtie> y \<rbrakk> \<Longrightarrow> snd\<^sub>l ;\<^sub>l (x \<times>\<^sub>l y) = y"
  apply (simp add: snd_lens_def prod_lens_def lens_comp_def comp_def)
  apply (subst lens_indep_comm)
  apply (simp_all)
done

subsection {* Mainly well-behaved lenses *}

locale mwb_lens = weak_lens +
  assumes put_put: "put (put \<sigma> v) u = put \<sigma> u"
begin

  lemma update_comp: "update f (update g \<sigma>) = update (f \<circ> g) \<sigma>"
    by (simp add: put_get put_put update_def)

end

declare mwb_lens.put_put [simp]

lemma mwb_lens_weak [simp]:
  "mwb_lens x \<Longrightarrow> weak_lens x"
  by (simp add: mwb_lens_def)

lemma comp_mwb_lens: "\<lbrakk> mwb_lens x; mwb_lens y \<rbrakk> \<Longrightarrow> mwb_lens (x ;\<^sub>l y)"
  by (unfold_locales, simp_all add: lens_comp_def)

lemma lens_indep_quasi_irrefl: "\<lbrakk> mwb_lens x; effectual x \<rbrakk> \<Longrightarrow> \<not> (x \<bowtie> x)"
  by (metis effectual_def lens_indep_def mwb_lens.put_put)

lemma lens_indep_left_comp:
  "\<lbrakk> mwb_lens z; x \<bowtie> y \<rbrakk> \<Longrightarrow> (x ;\<^sub>l z) \<bowtie> (y ;\<^sub>l z)"
  apply (rule lens_indepI)
  apply (auto simp add: lens_comp_def)
  apply (simp add: lens_indep_comm)
  apply (simp add: lens_indep_sym)
done

lemma lens_indep_right_comp:
  "y \<bowtie> z \<Longrightarrow> (x ;\<^sub>l y) \<bowtie> (x ;\<^sub>l z)"
  apply (auto intro!: lens_indepI simp add: lens_comp_def)
  using lens_indep_comm lens_indep_sym apply fastforce
  apply (simp add: lens_indep_sym)
done
  
lemma lens_indep_left_ext:
  "y \<bowtie> z \<Longrightarrow> (x ;\<^sub>l y) \<bowtie> z" 
  apply (auto intro!: lens_indepI simp add: lens_comp_def)
  apply (simp add: lens_indep_comm)
  apply (simp add: lens_indep_sym)
done

subsection {* Very well-behaved lenses *}

locale vwb_lens = wb_lens + mwb_lens
begin

  lemma source_determination:"get \<sigma> = get \<rho> \<Longrightarrow> put \<sigma> v = put \<rho> v \<Longrightarrow> \<sigma> = \<rho>"
    by (metis get_put put_put)

 lemma put_eq: 
   "\<lbrakk> get \<sigma> = k; put \<sigma> u = put \<rho> v \<rbrakk> \<Longrightarrow> put \<rho> k = \<sigma>"
   by (metis get_put put_put)   

end

lemma vwb_lens_wb [simp]: "vwb_lens x \<Longrightarrow> wb_lens x"
  by (simp_all add: vwb_lens_def)

lemma vwb_lens_mwb [simp]: "vwb_lens x \<Longrightarrow> mwb_lens x"
  by (simp_all add: vwb_lens_def)

lemma id_vwb_lens: "vwb_lens I\<^sub>l"
  by (unfold_locales, simp_all add: id_lens_def)

lemma unit_vwb_lens: "vwb_lens 0\<^sub>l"
  by (unfold_locales, simp_all add: unit_lens_def)

lemma comp_vwb_lens: "\<lbrakk> vwb_lens x; vwb_lens y \<rbrakk> \<Longrightarrow> vwb_lens (x ;\<^sub>l y)"
  by (unfold_locales, simp_all add: lens_comp_def)

lemma lens_comp_anhil [simp]: "wb_lens x \<Longrightarrow> 0\<^sub>l ;\<^sub>l x = 0\<^sub>l"
  by (simp add: unit_lens_def lens_comp_def comp_def)

lemma prod_vwb_lens:
  assumes "vwb_lens x" "vwb_lens y" "x \<bowtie> y"
  shows "vwb_lens (x \<times>\<^sub>l y)"
  using assms
  apply (unfold_locales, simp_all add: prod_lens_def)
  apply (simp add: lens_indep_sym prod.case_eq_if)
  apply (simp add: lens_indep_comm prod.case_eq_if)
done

lemma fst_vwb_lens: "vwb_lens fst\<^sub>l"
  by (unfold_locales, simp_all add: fst_lens_def prod.case_eq_if)

lemma snd_vwb_lens: "vwb_lens snd\<^sub>l"
  by (unfold_locales, simp_all add: snd_lens_def prod.case_eq_if)

subsection {* Bijective lenses *}

locale bij_lens = weak_lens +
  assumes strong_get_put: "put \<sigma> (get \<rho>) = \<rho>"
begin

sublocale vwb_lens
proof
  fix \<sigma> v u
  show "put \<sigma> (get \<sigma>) = \<sigma>"
    by (simp add: strong_get_put)
  show "put (put \<sigma> v) u = put \<sigma> u"
    by (metis put_get strong_get_put)
qed

lemma put_is_create: "put \<sigma> v = create v"
  by (metis create_get strong_get_put)

end

definition lens_inv :: "('a, 'b) lens \<Rightarrow> ('b, 'a) lens" where
"lens_inv x = \<lparr> lens_get = create\<^bsub>x\<^esub>, lens_put = \<lambda> \<sigma>. get\<^bsub>x\<^esub> \<rparr>"

lemma id_bij_lens: "bij_lens I\<^sub>l"
  by (unfold_locales, simp_all add: id_lens_def)

lemma inv_id_lens: "lens_inv I\<^sub>l = I\<^sub>l"
  by (auto simp add: lens_inv_def id_lens_def lens_create_def)

subsection {* Order and equivalence on lenses *}

definition sublens :: "('a, '\<alpha>) lens \<Rightarrow> ('b, '\<alpha>) lens \<Rightarrow> bool" (infix "\<subseteq>\<^sub>l" 55) where
"sublens x y = (\<exists> z :: ('a, 'b) lens. wb_lens z \<and> x = z ;\<^sub>l y)"

lemma sublens_refl:
  "x \<subseteq>\<^sub>l x"
  using id_wb_lens sublens_def by force

lemma sublens_trans:
  "\<lbrakk> x \<subseteq>\<^sub>l y; y \<subseteq>\<^sub>l z \<rbrakk> \<Longrightarrow> x \<subseteq>\<^sub>l z"
  apply (auto simp add: sublens_def lens_comp_assoc)
  apply (rename_tac z\<^sub>1 z\<^sub>2)
  apply (rule_tac x="z\<^sub>1 ;\<^sub>l z\<^sub>2" in exI)
  apply (simp add: lens_comp_assoc)
  using comp_wb_lens apply blast
done
 
lemma sublens_put_put:
  "\<lbrakk> mwb_lens x; y \<subseteq>\<^sub>l x \<rbrakk> \<Longrightarrow> lens_put x (lens_put y \<sigma> v) u = lens_put x \<sigma> u"
  by (auto simp add: sublens_def lens_comp_def)

lemma sublens_obs_get:
  "\<lbrakk> mwb_lens x; y \<subseteq>\<^sub>l x \<rbrakk> \<Longrightarrow>  get\<^bsub>y\<^esub> (put\<^bsub>x\<^esub> \<sigma> v) = get\<^bsub>y\<^esub> (put\<^bsub>x\<^esub> \<rho> v)"
  by (auto simp add: sublens_def lens_comp_def)

definition lens_equiv :: "('a, '\<alpha>) lens \<Rightarrow> ('b, '\<alpha>) lens \<Rightarrow> bool" (infix "\<approx>\<^sub>l" 51) where
"lens_equiv x y = (x \<subseteq>\<^sub>l y \<and> y \<subseteq>\<^sub>l x)"

lemma lens_equivI [intro]:
  "\<lbrakk> x \<subseteq>\<^sub>l y; y \<subseteq>\<^sub>l x \<rbrakk> \<Longrightarrow> x \<approx>\<^sub>l y"
  by (simp add: lens_equiv_def) 

lemma lens_equiv_refl:
  "x \<approx>\<^sub>l x"
  by (simp add: lens_equiv_def sublens_refl)

lemma lens_equiv_sym:
  "x \<approx>\<^sub>l y \<Longrightarrow> y \<approx>\<^sub>l x"
  by (simp add: lens_equiv_def)

lemma lens_equiv_trans:
  "\<lbrakk> x \<approx>\<^sub>l y; y \<approx>\<^sub>l z \<rbrakk> \<Longrightarrow> x \<approx>\<^sub>l z"
  by (auto intro: sublens_trans simp add: lens_equiv_def)

lemma unit_lens_indep: "0\<^sub>l \<bowtie> x"
  by (auto simp add: unit_lens_def lens_indep_def lens_equiv_def)

lemma fst_snd_id_lens: "fst\<^sub>l \<times>\<^sub>l snd\<^sub>l = I\<^sub>l"
  by (auto simp add: prod_lens_def fst_lens_def snd_lens_def id_lens_def)

lemma sublens_pres_indep:
  "\<lbrakk> x \<subseteq>\<^sub>l y; y \<bowtie> z \<rbrakk> \<Longrightarrow> x \<bowtie> z" 
  apply (auto intro!:lens_indepI simp add: sublens_def lens_comp_def lens_indep_comm)
  apply (simp add: lens_indep_sym)
done

lemma prod_pres_lens_indep: "\<lbrakk> x \<bowtie> z; y \<bowtie> z \<rbrakk> \<Longrightarrow> (x \<times>\<^sub>l y) \<bowtie> z"
  apply (rule lens_indepI)
  apply (simp_all add: prod_lens_def prod.case_eq_if)
  apply (simp add: lens_indep_comm)
  apply (simp add: lens_indep_sym)
done

lemma prod_lens_distr: "mwb_lens z \<Longrightarrow> (x \<times>\<^sub>l y) ;\<^sub>l z = (x ;\<^sub>l z) \<times>\<^sub>l (y ;\<^sub>l z)"
  by (auto simp add: lens_comp_def prod_lens_def comp_def)

lemma lens_comp_indep_cong_left:
  "\<lbrakk> mwb_lens z; x ;\<^sub>l z \<bowtie> y ;\<^sub>l z \<rbrakk> \<Longrightarrow> x \<bowtie> y"
  apply (rule lens_indepI)
  apply (rename_tac u v \<sigma>)
  apply (drule_tac u=u and v=v and \<sigma>="create\<^bsub>z\<^esub> \<sigma>" in lens_indep_comm)
  apply (simp add: lens_comp_def)
  apply (meson mwb_lens_weak weak_lens.view_determination)
  apply (rename_tac v \<sigma>)
  apply (drule_tac v=v and \<sigma>="create\<^bsub>z\<^esub> \<sigma>" in lens_indep_get)
  apply (simp add: lens_comp_def)
  apply (drule lens_indep_sym)
  apply (rename_tac u \<sigma>)
  apply (drule_tac v=u and \<sigma>="create\<^bsub>z\<^esub> \<sigma>" in lens_indep_get)
  apply (simp add: lens_comp_def)
done
  
lemma prod_pred_sublens: "\<lbrakk> mwb_lens z; x \<subseteq>\<^sub>l z; y \<subseteq>\<^sub>l z; x \<bowtie> y \<rbrakk> \<Longrightarrow> (x \<times>\<^sub>l y) \<subseteq>\<^sub>l z"
  apply (auto simp add: sublens_def)
  apply (rule_tac x="za \<times>\<^sub>l zaa" in exI)
  apply (auto intro!: prod_wb_lens)
  using lens_comp_indep_cong_left apply blast
  apply (simp add: prod_lens_distr)
done

lemma lens_prod_sub_assoc_1:
  "\<lbrakk> x \<bowtie> y; y \<bowtie> z; x \<bowtie> z \<rbrakk> \<Longrightarrow> x \<times>\<^sub>l y \<times>\<^sub>l z \<subseteq>\<^sub>l (x \<times>\<^sub>l y) \<times>\<^sub>l z"
  apply (simp add: sublens_def)
  apply (rule_tac x="(fst\<^sub>l ;\<^sub>l fst\<^sub>l) \<times>\<^sub>l (snd\<^sub>l ;\<^sub>l fst\<^sub>l) \<times>\<^sub>l snd\<^sub>l" in exI)
  apply (auto)
  apply (rule prod_wb_lens)
  apply (simp add: comp_vwb_lens fst_vwb_lens)
  apply (rule prod_wb_lens)
  apply (simp add: comp_vwb_lens fst_vwb_lens snd_vwb_lens)
  apply (simp add: snd_vwb_lens)
  apply (simp add: fst_snd_lens_indep lens_indep_left_ext)
  apply (rule lens_indep_sym)
  apply (rule prod_pres_lens_indep)
  using fst_snd_lens_indep fst_vwb_lens lens_indep_left_comp lens_indep_sym vwb_lens_mwb apply blast
  using fst_snd_lens_indep lens_indep_left_ext lens_indep_sym apply blast
  apply (auto simp add: prod_lens_def lens_comp_def fst_lens_def snd_lens_def prod.case_eq_if split_beta')[1]
done

lemma lens_prod_sub_assoc_2:
  "\<lbrakk> x \<bowtie> y; y \<bowtie> z; x \<bowtie> z \<rbrakk> \<Longrightarrow> (x \<times>\<^sub>l y) \<times>\<^sub>l z \<subseteq>\<^sub>l  x \<times>\<^sub>l y \<times>\<^sub>l z"
  apply (simp add: sublens_def)
  apply (rule_tac x="(fst\<^sub>l \<times>\<^sub>l (fst\<^sub>l ;\<^sub>l snd\<^sub>l)) \<times>\<^sub>l (snd\<^sub>l ;\<^sub>l snd\<^sub>l)" in exI)
  apply (auto)
  apply (rule prod_wb_lens)
  apply (rule prod_wb_lens)
  apply (simp add: fst_vwb_lens)
  apply (simp add: comp_vwb_lens fst_vwb_lens snd_vwb_lens)
  apply (rule lens_indep_sym)
  apply (rule lens_indep_left_ext)
  using fst_snd_lens_indep lens_indep_sym apply blast
  apply (auto intro: comp_wb_lens simp add: snd_vwb_lens)
  apply (rule prod_pres_lens_indep)
  apply (simp add: fst_snd_lens_indep lens_indep_left_ext lens_indep_sym)
  apply (simp add: fst_snd_lens_indep lens_indep_left_comp snd_vwb_lens)
  apply (auto simp add: prod_lens_def lens_comp_def fst_lens_def snd_lens_def prod.case_eq_if split_beta')[1]
done

lemma lens_prod_sub_assoc:
  "\<lbrakk> x \<bowtie> y; y \<bowtie> z; x \<bowtie> z \<rbrakk> \<Longrightarrow> (x \<times>\<^sub>l y) \<times>\<^sub>l z \<approx>\<^sub>l x \<times>\<^sub>l y \<times>\<^sub>l z"
  by (simp add: lens_equivI lens_prod_sub_assoc_1 lens_prod_sub_assoc_2)

lemma lens_prod_swap:
  "x \<bowtie> y \<Longrightarrow> (snd\<^sub>l \<times>\<^sub>l fst\<^sub>l) ;\<^sub>l (x \<times>\<^sub>l y) = (y \<times>\<^sub>l x)"
  by (auto simp add: prod_lens_def fst_lens_def snd_lens_def id_lens_def lens_comp_def lens_indep_comm)

lemma lens_prod_sub_comm: "x \<bowtie> y \<Longrightarrow> x \<times>\<^sub>l y \<subseteq>\<^sub>l y \<times>\<^sub>l x"
  apply (simp add: sublens_def)
  apply (rule_tac x="snd\<^sub>l \<times>\<^sub>l fst\<^sub>l" in exI)
  apply (auto)
  apply (simp add: fst_snd_lens_indep fst_vwb_lens lens_indep_sym prod_wb_lens snd_vwb_lens)
  apply (simp add: lens_indep_sym lens_prod_swap)
done
  
lemma lens_prod_comm: "x \<bowtie> y \<Longrightarrow> x \<times>\<^sub>l y \<approx>\<^sub>l y \<times>\<^sub>l x"
  by (simp add: lens_equivI lens_indep_sym lens_prod_sub_comm)

lemma lens_prod_ub: "wb_lens y \<Longrightarrow> x \<subseteq>\<^sub>l x \<times>\<^sub>l y"
  by (metis fst_lens_prod fst_vwb_lens sublens_def vwb_lens_wb)

lemma lens_comp_lb: "wb_lens x \<Longrightarrow> x ;\<^sub>l y \<subseteq>\<^sub>l y"
  using sublens_def by blast

lemma lens_unit_prod_sublens_1: "x \<subseteq>\<^sub>l 0\<^sub>l \<times>\<^sub>l x"
  by (metis lens_comp_lb snd_lens_prod snd_vwb_lens unit_lens_indep unit_wb_lens vwb_lens_wb)

lemma lens_unit_prod_sublens_2: "0\<^sub>l \<times>\<^sub>l x \<subseteq>\<^sub>l x"
  apply (auto simp add: sublens_def)
  apply (rule_tac x="0\<^sub>l \<times>\<^sub>l I\<^sub>l" in exI)
  apply (auto)
  apply (rule prod_wb_lens)
  apply (simp add: unit_wb_lens)
  apply (simp add: id_wb_lens)
  apply (simp add: unit_lens_indep)
  apply (auto simp add: prod_lens_def unit_lens_def lens_comp_def id_lens_def prod.case_eq_if comp_def)
  apply (rule ext)
  apply (rule ext)
  apply (auto)
done

lemma lens_restrict_mwb:
  "\<lbrakk> mwb_lens x; mwb_lens y; x \<subseteq>\<^sub>l y \<rbrakk> \<Longrightarrow> mwb_lens (x \\\<^sub>l y)"
  apply (unfold_locales)
  apply (auto simp add: lens_restrict_def lens_create_def sublens_def lens_comp_def comp_def)[1]
  apply (auto simp add: lens_restrict_def sublens_def lens_comp_def comp_def)
  apply (smt lens.select_convs(2) mwb_lens.put_put mwb_lens_weak weak_lens.put_get)
done  

subsection {* Lense implementations *}

definition fun_lens :: "'a \<Rightarrow> ('b, 'a \<Rightarrow> 'b) lens" where
"fun_lens x = \<lparr> lens_get = (\<lambda> f. f x), lens_put = (\<lambda> f u. f(x := u)) \<rparr>"

lemma fun_wb_lens: "wb_lens (fun_lens x)"
  by (unfold_locales, simp_all add: fun_lens_def)

lemma fun_lens_indep:
  "x \<noteq> y \<Longrightarrow> fun_lens x \<bowtie> fun_lens y"
  by (simp add: fun_lens_def lens_indep_def fun_upd_twist)

definition map_lens :: "'a \<Rightarrow> ('b, 'a \<rightharpoonup> 'b) lens" where
"map_lens x = \<lparr> lens_get = (\<lambda> f. the (f x)), lens_put = (\<lambda> f u. f(x \<mapsto> u)) \<rparr>"

lemma map_mwb_lens: "mwb_lens (map_lens x)"
  by (unfold_locales, simp_all add: map_lens_def)

definition list_pad_out :: "'a list \<Rightarrow> nat \<Rightarrow> 'a list" where
"list_pad_out xs k = xs @ replicate (k + 1 - length xs) undefined"

definition list_augment :: "'a list \<Rightarrow> nat \<Rightarrow> 'a \<Rightarrow> 'a list" where
"list_augment xs k v = (list_pad_out xs k)[k := v]"

definition nth' :: "'a list \<Rightarrow> nat \<Rightarrow> 'a" where
"nth' xs i = (if (length xs > i) then xs ! i else undefined)"

lemma list_update_append_lemma1: "i < length xs \<Longrightarrow> xs[i := v] @ ys = (xs @ ys)[i := v]"
  by (simp add: list_update_append)

lemma list_update_append_lemma2: "i < length ys \<Longrightarrow> xs @ ys[i := v] = (xs @ ys)[i + length xs := v]"
  by (simp add: list_update_append)

lemma list_augment_twice:
  "list_augment (list_augment xs i u) j v = list_pad_out xs (max i j)[i := u, j := v]"
  apply (auto simp add: list_augment_def list_pad_out_def list_update_append_lemma1 replicate_add[THEN sym] max_def)
  apply (metis Suc_le_mono add.commute diff_diff_add diff_le_mono le_add_diff_inverse2)
done

lemma list_augment_commute:
  "i \<noteq> j \<Longrightarrow> list_augment (list_augment \<sigma> j v) i u = list_augment (list_augment \<sigma> i u) j v"
  by (simp add: list_augment_twice list_update_swap max.commute)

lemma nth_list_augment: "list_augment xs k v ! k = v"
  by (simp add: list_augment_def list_pad_out_def)

lemma nth'_list_augment: "nth' (list_augment xs k v) k = v"
  by (auto simp add: nth'_def nth_list_augment list_augment_def list_pad_out_def)

lemma list_augment_same_twice: "list_augment (list_augment xs k u) k v = list_augment xs k v"
  by (simp add: list_augment_def list_pad_out_def)

lemma nth'_list_augment_diff: "i \<noteq> j \<Longrightarrow> nth' (list_augment \<sigma> i v) j = nth' \<sigma> j"
  by (auto simp add: list_augment_def list_pad_out_def nth_append nth'_def)

definition list_lens :: "nat \<Rightarrow> ('a, 'a list) lens" where
"list_lens i = \<lparr> lens_get = (\<lambda> xs. nth' xs i), lens_put = (\<lambda> xs x. list_augment xs i x) \<rparr>"

lemma list_mwb_lens: "mwb_lens (list_lens x)"
  by (unfold_locales, simp_all add: list_lens_def nth'_list_augment list_augment_same_twice)

lemma list_lens_indep:
  "i \<noteq> j \<Longrightarrow> list_lens i \<bowtie> list_lens j"
  by (simp add: list_lens_def lens_indep_def list_augment_commute nth'_list_augment_diff)

lemma sublens_least: "wb_lens x \<Longrightarrow> 0\<^sub>l \<subseteq>\<^sub>l x"
  using sublens_def unit_wb_lens by fastforce

lemma lens_nequiv_intro:
  "\<lbrakk> mwb_lens x; \<forall> u v \<sigma>. lens_put x (lens_put y \<sigma> v) u \<noteq> lens_put x \<sigma> u \<rbrakk> \<Longrightarrow> \<not> (x \<approx>\<^sub>l y)"
  by (meson lens_equiv_def sublens_put_put)

subsection {* Record field lenses *}

abbreviation "fld_put f \<equiv> (\<lambda> \<sigma> u. f (\<lambda>_. u) \<sigma>)"

syntax "_FLDLENS" :: "id \<Rightarrow> ('a, 'r) lens"  ("FLDLENS _")
translations "FLDLENS x" => "\<lparr> lens_get = x, lens_put = CONST fld_put (_update_name x) \<rparr>"

end