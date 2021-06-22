EndurenceVSBInjector.exe can be executed in 2 modes:
- Real-Time mode - events created in real-time constantly until stop, set fillRetention=0.
- Retention mode - Fill retention (X days backward) with events every day, set set fillRetention=1.
  Once the retention is filled, the events simulator will be stopped automatically.
  Relevant params for this mode: fillRetention, maxEventsPerDay and daysToFillRetention.
  For example, if current date is 10-Nov and you defined fillRetention=1, maxEventsPerDay=10000000 and daysToFillRetention=7
  The outcome will be 10M events every day from 02-Nov to 09-Nov so in total 70M events will be created.

Explanation for other params in EndurenceVSBInjector.exe.config:
1. sqlShadowDBPrefix and sqlShadowDBQuantity params - 
   Filer name exist in Varonis Management console UI --> Filers.
   In case only a single filer exist (such as "filer1"), write the full filer name in sqlShadowDBPrefix param such as sqlShadowDBPrefix="filer1" and set sqlShadowDBQuantity=1.
   In case multi-filers exist, for example filer1/filer2/filder3 then set sqlShadowDBPrefix="filer" and sqlShadowDBQuantity=3.

2. foldersAccessPath_sqlLikeExpression and usersSamAcountName_sqlLikeExpression params -
   Optional params, these params are defined in case you want to set your events to a specific users / folders.

3. eventType param - 
   Three events types are supported: cifs, ad and exchange.

4. EPS_inThousands param - 
   Set the desired EPS in case your fillRetention=0.
   note: this param is not relevant in case fillRetention=1 since you want to create the retention as quick as possible (target to 25K EPS).
