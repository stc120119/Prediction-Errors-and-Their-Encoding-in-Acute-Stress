data {
  int<lower=1> nSubjects;
  int<lower=1> nTrials;
  int<lower=1,upper=2> choice[nSubjects, nTrials];     
  real<lower=0, upper=1> reward[nSubjects, nTrials]; 
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
  vector[nSubjects] gamma_pr;    // 
  vector[nSubjects] tau_pr; // inverse temperature
}

transformed parameters {
  // subject-level parameters
  vector<lower=0, upper=1>[nSubjects] gamma;
  vector<lower=0, upper=10>[nSubjects] tau;


  for (i in 1:nSubjects) {
    gamma[i]   = Phi_approx(mu_pr[1]  + sigma[1]  * gamma_pr[i]);
    tau[i] = Phi_approx(mu_pr[2] + sigma[2] * tau_pr[i]) * 10;
  }
}

model {
  
  // Hyperparameters
  mu_pr  ~ normal(0, 1);
  sigma ~ normal(0, 1) T[0, ];

  // individual parameters
  gamma_pr ~ normal(0, 1);
  tau_pr ~ normal(0, 1);

  for (s in 1:nSubjects) {
    vector[2] v;    // value estimates
    real k;     // 动态学习率
    real pe;
    v = initV;      // initialize value estimates
    k = 0;
    

    for (t in 1:nTrials) {        
      choice[s,t] ~ categorical_logit( tau[s] * v );  // choice made based on softmax
      
      // Compute prediction error
      pe = reward[s,t] - v[choice[s,t]];
      
      // Update learning rate using Pearce-Hall rule
      k = gamma[s] * fabs(pe) + (1 - gamma[s]) * k; 
      
      // Update value estimates
      v[choice[s,t]] = v[choice[s,t]] +  k * pe ; 
    }
  }    
}

generated quantities {

  real log_lik[nSubjects,nTrials];
  int y_pred[nSubjects, nTrials];
  
  y_pred = rep_array(-999, nSubjects, nTrials);  // Initialize prediction array

  { // local section, this saves time and space
    for (s in 1:nSubjects) {
      vector[2] v;    // value estimates
      real pe;        // prediction error
      real k;     // dynamic learning rate
      v = initV;
      k = 0;

      for (t in 1:nTrials) {    
        log_lik[s,t] = categorical_logit_lpmf(choice[s,t] | tau[s] * v);    
        y_pred[s,t] = categorical_logit_rng( tau[s] * v ); 
        
        // Compute prediction error
        pe = reward[s,t] - v[choice[s,t]];

        // Update learning rate using Pearce-Hall rule
       k = gamma[s] * fabs(pe) + (1 - gamma[s]) * k; 
        
        // Update value estimates
        v[choice[s,t]] = v[choice[s,t]] +  k * pe; 
      }
    }    
  }
}

