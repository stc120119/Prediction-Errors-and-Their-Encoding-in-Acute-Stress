data {
  int<lower=1> nSubjects;
  int<lower=1> nTrials;
  int<lower=1,upper=2> choice[nSubjects, nTrials];     
  real<lower=0, upper=10> reward[nSubjects, nTrials]; 
}

transformed data {
  vector[2] initV;  // initial values for V
  initV = rep_vector(0.5, 2);
}

parameters {
// Declare all parameters as vectors for vectorizing
  // Hyper(group)-parameters
  vector[2] mu_pr;
  vector<lower=0>[2] sigma;
  
  // Subject-level raw parameters (for Matt trick)
  vector[nSubjects] alpha_pr;    // 
  vector[nSubjects] tau_pr; // inverse temperature
}

transformed parameters {
  // subject-level parameters
  vector<lower=0, upper=1>[nSubjects] alpha;
  vector<lower=0, upper=10>[nSubjects] tau;


  for (i in 1:nSubjects) {
    alpha[i]   = Phi_approx(mu_pr[1]  + sigma[1]  * alpha_pr[i]);
    tau[i] = Phi_approx(mu_pr[2] + sigma[2] * tau_pr[i]) * 10;
  }
}

model {
  
  // Hyperparameters
  mu_pr  ~ normal(0, 1);
  sigma ~ normal(0, 1) T[0, ];

  // individual parameters
  alpha_pr ~ normal(0, 1);
  tau_pr ~ normal(0, 1);

  for (s in 1:nSubjects) {

    vector[2] v; 
    real pe;    
    v = initV;

    for (t in 1:nTrials) {        
      choice[s,t] ~ categorical_logit( tau[s] * v );
            
      pe = reward[s,t] - v[choice[s,t]];   
    
      v[choice[s,t]] += alpha[s] * pe; 
      
    }
  }    
}

generated quantities {

  real log_lik[nSubjects, nTrials];
  int y_pred[nSubjects, nTrials];
  
  y_pred = rep_array(-999,nSubjects ,nTrials);

  { // local section, this saves time and space
    for (s in 1:nSubjects) {
      vector[2] v; 
      real pe;    
      v = initV;

      for (t in 1:nTrials) {    
        log_lik[s,t] = categorical_logit_lpmf(choice[s,t] | tau[s] * v);    
        y_pred[s,t] = categorical_logit_rng( tau[s] * v ); 
              
        pe = reward[s,t] - v[choice[s,t]];      
        v[choice[s,t]] += alpha[s] * pe;
      }
    }    
  }
}
