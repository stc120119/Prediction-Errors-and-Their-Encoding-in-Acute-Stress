data {
  int<lower=1> nSubjects;
  int<lower=1> nTrials;
  int<lower=1,upper=2> choice[nSubjects, nTrials];     
  real<lower=0, upper=10> reward[nSubjects, nTrials]; 
}

transformed data {
  vector[2] initV;
  initV = rep_vector(0.5, 2);
}

parameters {
  // Hyperparameters
  vector[3] mu_pr;
  vector<lower=0>[3] sigma;
  
  // Subject-level raw parameters

  vector[nSubjects] gamma_pos_raw;
  vector[nSubjects] gamma_neg_raw;
  vector[nSubjects] tau_raw;
}

transformed parameters {

  vector<lower=0, upper=1>[nSubjects] gamma_pos = Phi_approx(mu_pr[1] + sigma[1] * gamma_pos_raw);
  vector<lower=0, upper=1>[nSubjects] gamma_neg = Phi_approx(mu_pr[2] + sigma[2] * gamma_neg_raw);
  vector<lower=0, upper=10>[nSubjects] tau = 10 * Phi_approx(mu_pr[3] + sigma[3] * tau_raw);
}

model {
  // Priors
  mu_pr ~ normal(0, 1);
  sigma ~ normal(0, 1) T[0, ];
  
  // Individual-level parameters

  gamma_pos_raw ~ normal(0, 1);
  gamma_neg_raw ~ normal(0, 1);
  tau_raw ~ normal(0, 1);
  
  // Likelihood
  for (s in 1:nSubjects) {
    vector[2] v = initV;
    real k = 0;
    
    for (t in 1:nTrials) {        
      choice[s,t] ~ categorical_logit(tau[s] * v);
      
      // 计算预测误差
      real pe = reward[s,t] - v[choice[s,t]];
      
      // 使用Pearce-Hall规则更新学习率
      if (pe > 0){
        k = gamma_pos[s] * fabs(pe) + (1 - gamma_pos[s]) * k; 
      } else {
        k = gamma_neg[s] * fabs(pe) + (1 - gamma_neg[s]) * k;
      }
      
      // 更新价值估计
      v[choice[s,t]] += k * pe; 
    }
  }
}

generated quantities {
  real log_lik[nSubjects, nTrials];
  int y_pred[nSubjects, nTrials];
  
  y_pred = rep_array(-999, nSubjects, nTrials);  // 初始化预测数组
  
  for (s in 1:nSubjects) {
    vector[2] v = initV;
    real k = 0;
    
    for (t in 1:nTrials) {    
      log_lik[s,t] = categorical_logit_lpmf(choice[s,t] | tau[s] * v); 
      y_pred[s, t] = categorical_rng(softmax(tau[s] * v));
      
      // 计算预测误差
      real pe = reward[s,t] - v[choice[s,t]];
      
      // 使用Pearce-Hall规则更新学习率
      if (pe > 0){
        k = gamma_pos[s] * fabs(pe) + (1 - gamma_pos[s]) * k; 
      } else {
        k = gamma_neg[s] * fabs(pe) + (1 - gamma_neg[s]) * k;
      }
      
      // 更新价值估计
      v[choice[s,t]] += k * pe; 
    }
  }
}
