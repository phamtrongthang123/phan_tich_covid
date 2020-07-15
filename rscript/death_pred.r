covid_data <- read.csv("mydata/merged.csv")
covid_data$date <- as.Date(covid_data$date)

library(ggplot2)

extract_region <- function(data, country) {
  res <- covid_data[covid_data$location == country,]
  res$NewCases <- c(0, diff(res$Confirmed))
  res$NewRecovered <- c(0, diff(res$Recovered))
  res$NewDeaths <- c(0, diff(res$Deaths))
  
  res$NewConfirmed[is.na(res$Confirmed)] = 0
  res$NewDeaths[is.na(res$Deaths)] = 0
  
  res$new_cases[is.na(res$new_cases)] = 0
  res$new_deaths[is.na(res$new_deaths)] = 0
  
  res$NewRecovered[is.na(res$Recovered)] = 0
  
  res$DateIndex <- unclass(res$date)
  res$NewCasesSmooth <- loess(NewCases ~ DateIndex, data=res, span=0.1)$fitted
  res$NewRecoveredSmooth <- loess(NewRecovered ~ DateIndex, data=res, span=0.1)$fitted
  res$NewDeathsSmooth <- loess(NewDeaths ~ DateIndex, data=res, span=0.1)$fitted
  res
}


#model here

pred <- function(pad_data, pdf) {
  l <- length(pdf) - 1
  res <- (filter(pad_data, pdf, method = "convolution", sides = 1, circular = FALSE, init = 0))
  return(tail(res,-l))  
}
# 
# pred_grad <- function(pad_data, pdf_grad) {
#   l <- length(pdf) - 1
#   res <- (filter(pad_data, pdf, method = "convolution", sides = 1, circular = FALSE, init = 0))
#   return(tail(res,-l))  
# }

residue <- function(truth, pad_data, pdf) {
  pr <- pred(pad_data,pdf)
#  plot(pr)
#  lines(truth)
  
  return(pr - truth)
}

loss2 <- function(truth, pad_data, pdf) {
  l <- (norm(residue(truth, pad_data, pdf), type="2"))
  #print(l)
  return(l)
}

loss <- function(truth, pad_data, pdf) {
  l <- (norm(cumsum(residue(truth, pad_data, pdf)), type="2"))
  l
}




loss2 <- function(truth, pad_data, pdf) {
  l <- (mean(cumsum(residue(truth, pad_data, pdf))^2/(abs(truth)+1)))
  print(l)
  return(l)
}


loss2 <- function(truth, pad_data, pdf) {
  l <- (mean(cumsum(residue(truth, pad_data, pdf))^2/(abs(cumsum(truth))+1)))
  print(l)
  return(l)
}

softplus <- function(x) {
  ifelse(x > 20, x, log1p(1+exp(x)))
}


softplus_d <- function(x) {
  ifelse(x > 20, 1, 1/(1+exp(-x)))
}

pdf_param <-function(param,l) {
  param[1:2] <- softplus(param[1:2])
  x <- 0:l
  size <- param[2]
  mu <- param[1]
  pdf <- (dnbinom(x, size = param[2], mu = param[1])) * param[3];
  pdf
}

pdf_grad_param <-function(param,l) {
  param_grad <- softplus_d(param[1:2])
  param[1:2] <- softplus(param[1:2])
  x <- 0:l
  size <- param[2]
  mu <- param[1]
  p <- size/(size + mu)
  grad_size <- digamma(x + size) - digamma(size) + log(p) + 1 - p - x/(size + mu)
  grad_p <- size/p - x/(1-p)
  
  
  pdf <- (dnbinom(x, size = param[2], mu = param[1]));
  
  #d_p_size =  size/(size+mu)^2
  d_p_mu <- -size/(size+mu)^2
  grad_mu <- grad_p * d_p_mu
  
  grad_par1 <- grad_mu * param[3] * param_grad[1]
  grad_par2 <- grad_size  * param[3] * param_grad[2]
  
  pdf_grad <- list(
    pdf * grad_par1 ,
    pdf * grad_par2,
    pdf
  )
}

add_pad <- function(data, l) {
  return(c(rep(data[1], l), data))
}

fit <- function(truth, data, l,init = c(7, 1, 30, 1, 0.12), pad = T, method = "CG") {
  if (pad) {
    data <- add_pad(data, l)
  }
  
  eval <- function(truth, pad_data, param){
    loss(truth, data, pdf_param(param, l))
  }
  
  loss_grad_norm <- function(pad_data, pdf_grad) {
    2 * cumsum(pred(pad_data,pdf_grad))
  }
  
  grad <- function(truth, pad_data, param){
    pdf <- pdf_param(param, l)
    res <- cumsum(residue(truth, pad_data, pdf))
    loss <- norm(res, type="2")
    res <- res / (2 * loss)
    
    pdf_grad <- pdf_grad_param(param, l)
    c(
      loss_grad_norm(pad_data, pdf_grad[[1]]) %*%res,
      loss_grad_norm(pad_data, pdf_grad[[2]]) %*%res,
      loss_grad_norm(pad_data, pdf_grad[[3]]) %*%res
    )
  }
  
  s1 <- sum(truth$deaths) + 1
  s2 <- sum(truth$recovered) + 1
  
  fn <-  function(param) {
    l <- eval(truth$deaths, data, c(param[1],param[2], param[5]))/s1 +
      eval(truth$recovered, data, c(param[3],param[4], 1 - param[5]))/s2
    print(l)
    l
  }
  
  gr <-  function(param) {
    #print(param)
    gd <- grad(truth$deaths, data, c(param[1],param[2], param[5])) / s1
    gr <-grad(truth$recovered, data, c(param[3],param[4], 1 - param[5])) / s2
    res <- c  (
      gd[1],
      gd[2],
      gr[1],
      gr[2],
      gd[3]-gr[3]
    )
    print(res)
    res
  } 
  
  if (method == "GD") {
    grad_descend(init, fn, gr, 0.01)
  } else {
   optim(init, fn = fn, gr = gr, method = method)
  }
}



plot_model <- function(truth, data, param, l, pad = T) {
  if (pad) {
    data <- add_pad(data, l)
  }
  pdf <- pdf_param(param, l)
  pr <- pred(data, pdf)
  plot(pr)
  lines(truth)
}


plot_csum_model <- function(truth, data, param, l, pad = T) {
  if (pad) {
    data <- add_pad(data, l)
  }
  pdf <- pdf_param(param, l)
  pr <- pred(data, pdf)
  plot(cumsum(pr))
  lines(cumsum(truth))
}
# 

grad_descend <- function(param, fn, grad, lr) {
  old_res = 0
  res <- fn(param)
  while(abs(old_res-res) > 0.01) {
    param = param - grad(param) * lr
    old_res <- res
    res <- fn(param)
  }
  param
}

country = "US"
data <- extract_region(covid_data, country)

ggplot(data, aes(x = date)) + geom_line(aes(y=new_cases), color = "blue", size = 1) + geom_line(aes(y=new_deaths), color = "red", size = 1) + geom_line(aes(y=NewRecovered), color = "green", size = 1)

#fitting BFGS Nelder-Mead L-BFGS-B CG SANN
mod <- fit(method= "BFGS", list(deaths = data$new_deaths, recovered = data$NewRecovered), data$new_cases, 100, init = c(7, 1, 37, 2, 0.12))
#refine
mod <- fit(method= "Nelder-Mead", list(deaths = data$new_deaths, recovered = data$NewRecovered), data$new_cases, 100, init = mod$par)
#final loss
print(mod$value)

par <- mod$par; par[1:4] <- softplus(par[1:4])
print(par)

plot_csum_model(data$NewDeaths, data$NewCases, c(mod$par[1], mod$par[2], mod$par[5]), 100)
plot_model    (data$NewDeaths, data$NewCases,  c(mod$par[1], mod$par[2], mod$par[5]), 100)


plot_csum_model(data$NewRecovered, data$NewCases, c(mod$par[3], mod$par[4], 1 - mod$par[5]), 100)
plot_model    (data$NewRecovered, data$NewCases,  c(mod$par[3], mod$par[4], 1 -mod$par[5]), 100)