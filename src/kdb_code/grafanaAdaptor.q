//############################################################################
//
// Thhis script is used to connect grafana to kdb
//
//############################################################################

.gf.trackQueries:([]time:`timestamp$();queryAsString:());

csvToSyms:{`$","vs(ssr[;;""])/[x;("(";")")]};

{x set y}'[`.lg.info`.lg.error`.lg.debug;
  ({-1"[*INFO]|",string[.z.p],"|",x};
   {-2"[ERROR]|",string[.z.p],"|",x};
   {if[system"e";-2"[DEBUG]|",string[.z.p],"|",x]})];

.z.pp:{
  .lg.debug"Received message from grafana ...";
  //parse the incoming query 
  x:parseQuery[x];
  x:resolveQuery[x];
  //send back response
  sendResponse[x]
  };

parseQuery:{
  .lg.debug"Parsing query ...";
  x:x[0];
  //log query to tracking table
  logQuery[x];
  JSONMessage:last" "vs x;
  parsedDict:.j.k JSONMessage;
  parsedDict
  };

resolveQuery:{
  .lg.debug"Evaluating query ...";
  value(raze x`targets)`target
 }

logQuery:{
  .lg.debug"Logging query to tracking table ...";
 };

sendResponse:{
  .lg.debug"Sending response ...";
  .h.hy[`json].j.j x
  };