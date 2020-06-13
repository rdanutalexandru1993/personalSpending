//######################################################################################################################
//
//         Date: 2020.06
//       Author: A D Risnoveanu
//  Description: Script to extract and manipulate the spending.csv and create call functions for creating the dashboards
//   Start Line: 
//######################################################################################################################

//######################################################################################################################
//  LOADING NECESSARY FILES
//######################################################################################################################

system"l /media/alex/cf35aee0-faeb-40bb-adac-88595e8f71fe/alex_hdd/crtFolder/2020/personal_spending/src/kdb_code/grafanaAdaptor.q";

//######################################################################################################################
//  SETTING UP ENVIRONMENT VARIABLES
//######################################################################################################################
setenv[`pspending_data_folder;"/media/alex/cf35aee0-faeb-40bb-adac-88595e8f71fe/alex_hdd/crtFolder/2020/personal_spending/data/"];

//######################################################################################################################
//  SETTING UP GLOBAL VARIABLES
//######################################################################################################################
cmdline:.Q.opt[.z.x]; 
.data.gSpending:string $[`genericSpending in key cmdline;first cmdline`file;`spending_newformat.csv];
.data.rSpending:string $[`regularSpending in key cmdline;first cmdline`file;`regular_spending.csv];

//######################################################################################################################
//  UTILITY FUNCTIONS
//######################################################################################################################
.util.parseCSVFile:{
  //function to parse the csv files loaded in the script 
  :$[x in`.data.genericSpending;
       `date xasc update date:"D"$ssr[;"-";"."]each date,"F"$amount from y; 
     x in`.data.regularSpending;
       update start_date:{$[not x like"";"D"$ssr[x;"/";"."];"D"$x]}'[start_date],
              end_date:{$[not x like"";"D"$ssr[x;"/";"."];"D"$x]}'[end_date]from y;
     y
     ];
  };

.util.getStartEndLastWeek:{[byDay]
  //function to get the last week dates
  sd:.z.d+neg a+neg[1]+a:`dd$.z.d;
  :$[byDay;sd+til 6;(sd;sd+6)];
  };

.util.pivTab:{[pCN;pRN;vl;tb]
  //generic function to pivot a table
  P:?[tb;();();(?:;pCN)];
  :?[tb;();(enlist pRN)!enlist pRN;(#;`P;(!;pCN;vl))];
  };

.util.getUNIXEpoch:{%[(`long$x)+neg`long$`timestamp$1970.01.01;1e6]};

.util.monthConv:`January`February`March`April`May`June`July`August`September`October`November`December;
//######################################################################################################################
//  LOADING NECESSARY DATA
//######################################################################################################################
.data.genericSpending:.util.parseCSVFile[`.data.genericSpending;]("*SS*";enlist",")0:
  hsym`$getenv[`pspending_data_folder],.data.gSpending;
.data.regularSpending:.util.parseCSVFile[`.data.regularSpending;]("ISSFI**";enlist",")0:
  hsym`$getenv[`pspending_data_folder],.data.rSpending;

//######################################################################################################################
//  ANALYSIS
//######################################################################################################################
.analysis.getLastWeek:{[d]
  //function to extract by date,by category
  t:select from d[`t]where date within .util.getStartEndLastWeek[0b]; 
  ct:exec distinct category from t where date=@[;`date]first 0!`category xdesc select count distinct category 
    by date from t;
  keyfields:exec distinct category from t where date=@[;`date]first 0!`category xdesc select count distinct category 
    by date from t;
  t:update date:"D"$first each"_"vs/:string keyFields from keyfields lj`keyFields xkey 
    select keyFields:{`$"_"sv string(x;y)}'[date;category],amount from t;

  break32231;
  };

.analysis.getLastNDay:{[d]
  //noDays - number of days 
  //dNice - display nice 
  //byClause - specify the byClause

  //to get the previous n days
  res:select from .data.genericSpending where date in .z.d - til d`noDays; 
  if[`byClause in key d;
      byClause:$[`~d`byClause;enlist[`date]!enlist`date;(`date,d`byClause)!`date,d`byClause];
      res:?[res;();byClause;(enlist`amount)!enlist(sum;`amount)]];
  if[`dNice in key d;res:.util.pivTab[`category;`date;`amount;res]];
  :res;
  };

.analysis.getLastDay:{[d]
  dt:$[`date in key d;d`date;.z.d-1];
  //get last day of spending 
  t:select from d[`t]where date=dt; 
  :select sum amount by date,category from t;
  };

.analysis.getSpendingByYear:{[x]
  //get the spending by year
  //parameter is `grafana or `local
  ret:0!select sum amount by year:`year$date from .data.genericSpending;
  if[x~`grafana;
      ret:update target:year,year:{.util.getUNIXEpoch"P"$string[x],".01.01D00:06:00.000"}'[year]from ret;
      ret:delete year,amount from update string target,datapoints:{enlist(x;y)}'[amount;year]from ret;
    ];
  ret
 };
//.analysis.getSpendingByYear enlist[`data]!enlist .data.genericSpending

.analysis.getSpendingByMonthYear:{[d]
  //get spending by month per year
  res:select sum amount by month:(`month$date),year:(`year$date) from d`data;
  res:update month:.util.monthConv neg[1]+"I"$last each"."vs/:string month from res;
  :`year xkey .util.monthConv xcols 0!.util.pivTab[`month;`year;`amount;0!res];
 };


