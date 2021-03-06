section {* Derivatives: extra laws and tactics *}

theory Derivative_extra
  imports
  "HOL-Analysis.Derivative"
  "HOL-Eisbach.Eisbach"
begin

subsection {* Properties of filters *}

lemma filtermap_within_range_minus: "filtermap (\<lambda> x. x - n::real) (at y within {x..<y}) = (at (y - n) within ({x-n..<y-n}))"
  by (simp add: filter_eq_iff eventually_filtermap eventually_at_filter filtermap_nhds_shift[symmetric])

lemma filtermap_within_range_plus: "filtermap (\<lambda> x. x + n::real) (at y within {x..<y}) = (at (y + n) within ({x+n..<y+n}))"
  using filtermap_within_range_minus[of "-n"] by simp

lemma filter_upto_contract:
  "\<lbrakk> (x::real) \<le> y; y < z \<rbrakk> \<Longrightarrow> (at z within {x..<z}) = (at z within {y..<z})"
  by (rule at_within_nhd[of _ "{y<..<z+1}"], auto)

subsection {* Topological Spaces *}
  
instantiation unit :: t2_space
begin
  definition open_unit :: "unit set \<Rightarrow> bool" where "open_unit = (\<lambda> _. True)"
  instance by (intro_classes, simp_all add: open_unit_def)
end
 
subsection {* Extra derivative rules *}

lemma has_vector_derivative_Pair [derivative_intros]:
  "\<lbrakk> (f has_vector_derivative f') (at x within s); (g has_vector_derivative g') (at x within s) \<rbrakk> \<Longrightarrow>
      ((\<lambda> x. (f x, g x)) has_vector_derivative (f', g')) (at x within s)"
  by (auto intro: has_derivative_Pair simp add: has_vector_derivative_def)

lemma has_vector_derivative_power[simp, derivative_intros]:
  fixes f :: "real \<Rightarrow> 'a :: real_normed_field"
  assumes f: "(f has_vector_derivative f') (at x within s)"
  shows "((\<lambda>x. f x^n) has_vector_derivative (of_nat n * f' * f x^(n - 1))) (at x within s)"
  using assms
  apply (simp add: has_vector_derivative_def)
  apply (subst has_derivative_eq_rhs)
  apply (rule has_derivative_power)
  apply (auto)
done

lemma has_vector_derivative_divide[simp, derivative_intros]:
  fixes f :: "real \<Rightarrow> 'a :: real_normed_div_algebra"
  assumes f: "(f has_vector_derivative f') (at x within s)"
      and g: "(g has_vector_derivative g') (at x within s)"
  assumes x: "g x \<noteq> 0"
  shows "((\<lambda>x. f x / g x) has_vector_derivative
                (- f x * (inverse (g x) * g' * inverse (g x)) + f' / g x)) (at x within s)"
  using assms
  apply (simp add: has_vector_derivative_def)
  apply (subst has_derivative_eq_rhs)
  apply (rule has_derivative_divide)
  apply (auto simp add: divide_inverse real_vector.scale_right_diff_distrib)
done

lemma Pair_has_vector_derivative:
  assumes "(f has_vector_derivative f') (at x within s)"
    "(g has_vector_derivative g') (at x within s)"
  shows "((\<lambda>x. (f x, g x)) has_vector_derivative (f', g')) (at x within s)"
  using assms
  by (auto simp: has_vector_derivative_def intro!: derivative_eq_intros)
  
lemma has_vector_derivative_fst:
  assumes "((\<lambda>x. (f x, g x)) has_vector_derivative (f', g')) (at x within s)"
  shows "(f has_vector_derivative f') (at x within s)"
  using assms
  by (auto simp: has_vector_derivative_def intro!: derivative_eq_intros dest: has_derivative_fst)

lemma has_vector_derivative_fst' [derivative_intros]:
  assumes "(f has_vector_derivative (f', g')) (at x within s)"
  shows "(fst \<circ> f has_vector_derivative f') (at x within s)"
proof -
  have "(\<lambda> x. (fst (f x), snd (f x))) = f"
    by (simp)
  with assms have "((\<lambda> x. (fst (f x), snd (f x))) has_vector_derivative (f', g')) (at x within s)"
    by (simp)
  thus ?thesis
    by (drule_tac has_vector_derivative_fst, simp add: comp_def)
qed
    
lemma has_vector_derivative_snd:
  assumes "((\<lambda>x. (f x, g x)) has_vector_derivative (f', g')) (at x within s)"
  shows "(g has_vector_derivative g') (at x within s)"
  using assms
  by (auto simp: has_vector_derivative_def intro!: derivative_eq_intros dest: has_derivative_snd)

lemma has_vector_derivative_snd'' [derivative_intros]:
  assumes "(f has_vector_derivative (f', g')) (at x within s)"
  shows "(snd \<circ> f has_vector_derivative g') (at x within s)"
proof -
  have "(\<lambda> x. (fst (f x), snd (f x))) = f"
    by (simp)
  with assms have "((\<lambda> x. (fst (f x), snd (f x))) has_vector_derivative (f', g')) (at x within s)"
    by (simp)
  thus ?thesis
    by (drule_tac has_vector_derivative_snd, simp add: comp_def)
qed

lemma Pair_has_vector_derivative_iff:
  "((\<lambda>x. (f x, g x)) has_vector_derivative (f', g')) (at x within s) \<longleftrightarrow>
   (f has_vector_derivative f') (at x within s) \<and> (g has_vector_derivative g') (at x within s)"
  using Pair_has_vector_derivative has_vector_derivative_fst has_vector_derivative_snd by blast
  
text {* The next four rules allow us to prove derivatives when the function is equivalent to
  another a function when approach from the left or right. *}
 
lemma has_derivative_left_point:
  fixes f g :: "real \<Rightarrow> real"
  assumes "(f has_derivative f') (at x within s)" "x \<in> s" "x < y" "\<forall>x'<y. f x' = g x'"
  shows "(g has_derivative f') (at x within s)"
  apply (rule has_derivative_transform_within[of f f' x s "y-x" g])
  apply (simp_all add: assms dist_real_def)
done
  
lemma has_derivative_right_point:
  fixes f g :: "real \<Rightarrow> real"
  assumes "(f has_derivative f') (at x within s)" "x \<in> s" "x > y" "\<forall>x'>y. f x' = g x'"
  shows "(g has_derivative f') (at x within s)"
  apply (rule has_derivative_transform_within[of f f' x s "x-y" g])
  apply (simp_all add: assms dist_real_def)
done
  
lemma has_vector_derivative_left_point:
  fixes f g :: "real \<Rightarrow> real"
  assumes "(f has_vector_derivative f') (at x within s)" "x \<in> s" "x < y" "\<forall>x'<y. f x' = g x'"
  shows "(g has_vector_derivative f') (at x within s)"
  using assms
  apply (simp add: has_vector_derivative_def)
  apply (rule_tac y="y" and f="f" in has_derivative_left_point)
  apply (auto simp add: assms)
done

lemma has_vector_derivative_right_point:
  fixes f g :: "real \<Rightarrow> real"
  assumes "(f has_vector_derivative f') (at x within s)" "x \<in> s" "x > y" "\<forall>x'>y. f x' = g x'"
  shows "(g has_vector_derivative f') (at x within s)"
  using assms
  apply (simp add: has_vector_derivative_def)
  apply (rule_tac y="y" and f="f" in has_derivative_right_point)
  apply (auto simp add: assms)
done
  
lemma max_simps [simp]: 
  "(y::real) < max x y \<longleftrightarrow> y < x" 
  "x < max x y \<longleftrightarrow> x < y"
  "max x y = y \<longleftrightarrow> x \<le> y"
  by auto
    
lemma min_simps [simp]:
  "min (x::real) y < x \<longleftrightarrow> y < x"
  "min x y < y \<longleftrightarrow> x < y"
  by auto

end