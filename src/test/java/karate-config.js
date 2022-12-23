function fn() {
  var env = karate.env; // get system property 'karate.env'
  karate.log('karate.env system property was:', env);
  if (!env) {
    env = 'qc1';
  }
  var config = {
    env: env,
    myVarName: 'someValue'
  }
  var appConfig = karate.read('classpath:Environments/'+env +'/config.yaml');
  config  = karate.merge(config, appConfig)
  return config;
}