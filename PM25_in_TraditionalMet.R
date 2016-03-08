setwd("D:/����/math/ʱ������/ʱ�����д���ҵ")
tmpvec<-scan("������ʷ������ѯ.txt",what="",sep=",");
t=data.frame(matrix(tmpvec[-length(tmpvec)],ncol=4,byrow=T),"����"="����",stringsAsFactors=F)
colnames(t)<-c("����","����","�¶�","����","����")

tmpvec2<-scan("����.txt",what="",sep=",");
t2=data.frame(matrix(tmpvec2[-length(tmpvec2)],ncol=7,byrow=T),"����"="����",stringsAsFactors=F)
colnames(t2)=c("����","AQIָ��","PM2.5","PM10","Co","No2","So2","����")
for(i in 2:7)
{
  t2[,i]<-as.numeric(t2[,i])
}

dt1<-read.table("������������.txt",sep=",",head=T)
dt1[,1]<-as.character(as.Date(dt1$CST),format="%Y-%m-%d")
colnames(dt1)<-c("����",colnames(dt1)[-1])

dt_merge<-merge(dt1,t2,by="����",stringsAsFactors=F)
dt_merge<-data.frame(dt_merge[,-c(19,21,22,30)])

x<-as.matrix(dt_merge[,c(2:ncol(dt_merge))])
y<-as.matrix(dt_merge$PM2.5[-1])
index<-complete.cases(x)
x<-x[index,]
y<-y[index]
sizex<-nrow(x)
##index<-sample(1:sizex,sizex*1/2)
index<-c(1:(3/4*sizex))
trainx<-x[index,]
trainy<-y[index]
testx<-x[-index,]
testy<-y[-index]
testx<-testx[-nrow(testx),]
testy<-testy[-length(testy)]

#ʱ��ͼ
tsy<-ts(trainy,start=2013,frequency=365)
plot.ts(tsy)
par(mfrow=c(2,1))
acf(trainy)
pacf(trainy)
#һ�ײ��
Diff_1_trainy<-diff(trainy)
acf(Diff_1_trainy)
pacf(Diff_1_trainy)
library(tseries)
#pp����
pp.test(Diff_1_trainy,alt="stationary")
#��������飺Box-Pierce��Ljung-Box
Box.test(Diff_1_trainy,lag=1,type="Box-Pierce")
Box.test(Diff_1_trainy,lag=1,type="Ljung-Box")
#ARIMA
library(forecast)
arima.sol<-auto.arima(Diff_1_trainy)
print(arima.sol)
arima.pre<-predict(arima.sol,newdata=Diff_1_trainy)
res<-forecast(arima.sol)$residuals
acf(res)
pacf(res)
res2<-res^2
acf(res2)
pacf(res2)
Box.test(res)
pp.test(res)
library(FinTS)
ArchTest(trainy)
plot(diff(trainy),type="l")
plot(forecast(arima.sol,))
library(fGarch)
garch11.sol<-garchFit(formula=~arma(1,1)+garch(1,1),data=Diff_1_trainy,con.dist="ged")
summary(garch11.sol)
garch12.sol<-garchFit(formula=~arma(1,1)+garch(1,2),data=Diff_1_trainy,con.dist="ged")
summary(garch12.sol)
garch21.sol<-garchFit(formula=~arma(1,1)+garch(2,1),data=Diff_1_trainy,con.dist="ged")
summary(garch21.sol)
#���ɷݷ���
px<-trainx[,-which(colnames(trainx)=="PM2.5")]
princomp_x<-princomp(px)
plot(princomp_x,type="l")
px<-predict(princomp_x)[,1:4]
ptx<-predict(princomp_x,x[,-which(colnames(x)=="PM2.5")])[,1:4]
princ_x<-cbind(x[,which(colnames(x)=="PM2.5")],ptx)
#princ_x<-diff(princ_x,lag=2)

princ_trainx<-cbind(trainx[,which(colnames(trainx)=="PM2.5")],px)
#princ_trainx<-diff(princ_trainx,lag=2)

#KPSS��Johansen����
library(tseries)
#����
for(i in 1:5)
{
  print(i)
  print(pp.test(princ_trainx[,i],"stationary"))
  print(kpss.test(princ_trainx[,i],"Level"))
  print(kpss.test(princ_trainx[,i],"Trend"))
  print(pp.test(diff(princ_trainx[,i]),"stationary"))
  print(kpss.test(diff(princ_trainx[,i]),"Level"))
  print(kpss.test(diff(princ_trainx[,i]),"Trend"))
}
#Э��
library("urca")
summary(ca.jo(princ_trainx,type="trace",ecdet="const"))
summary(ca.jo(princ_trainx,type="eigen",ecdet="const"))
summary(ca.jo(princ_trainx,type="trace",ecdet="trend"))
summary(ca.jo(princ_trainx,type="eigen",ecdet="trend"))
#VAR
library(vars)

#������ֵ�varxЧ������
AIC_lag<-VARselect(princ_trainx,lag.max=10,type="none")$selection[1]
var_none<-VAR(princ_trainx,p=AIC_lag)
plot(predict(var_none,n.ahead=8,ci=0.95))

AIC_lag<-VARselect(princ_trainx,lag.max=10,type="const")$selection[1]
var_const<-VAR(princ_trainx,p=AIC_lag)
plot(predict(var_none,n.ahead=8,ci=0.95))

AIC_lag<-VARselect(princ_trainx,lag.max=10,type="trend")$selection[1]
var_trend<-VAR(princ_trainx,p=AIC_lag)
plot(predict(var_none,n.ahead=8,ci=0.95))

AIC_lag<-VARselect(princ_trainx,lag.max=10,type="both")$selection[1]
var_both<-VAR(princ_trainx,p=AIC_lag)
plot(predict(var_none,n.ahead=8,ci=0.95))
#VARX
library(dse)
fld<-TSdata(input=princ_x[index,2:5],output=princ_x[index,1])
fldtest<-TSdata(input=princ_x[,2:5],output=princ_x[,1])
fld.ls<-estVARXls(fld,max.lag=7)
print(fld.ls)
dse::stability(fld.ls)
rr=checkResiduals(fld.ls)
f.p<-dse::forecast(fld.ls,conditioning.inputs.forecasts=princ_x[-index,2:5])
tfplot(f.p)
plot(as.numeric(f.p$forecast[[1]]),type="l",col="red",main="Ԥ��ͼ",lwd=3)
lines(princ_x[-index,1],col="blue",lwd=3)
legend("topleft",legend=c("��ʵֵ","Ԥ��ֵ"),lty=c(5:1),lwd=2,,col=c("blue","red"))
plot(as.numeric(f.p$forecast[[1]]),princ_x[-index,1],pch="��",xlab="Ԥ��ֵ",ylab="��ʵֵ",main="Ԥ��VS��ʵ")
psse<-sqrt(mean((f.p$forecast[[1]]-princ_x[-index,1])^2))
rse<-mean(abs((f.p$forecast[[1]]-princ_x[-index,1])/princ_x[-index,1]))
#״̬�ռ�ģ��
fld.ss<-estSSfromVARX(fld,max.lag=7)
print(fld.ss)
dse::stability(fld.ss)
rr=checkResiduals(fld.ss)
f.p2<-forecast(fld.ss,conditioning.inputs.forecasts=princ_x[-index,2:5])
tfplot(f.p2)
plot(as.numeric(f.p2$forecast[[1]]),type="l",col="red",main="Ԥ��ͼ",lwd=3)
lines(princ_x[-index,1],col="blue",lwd=3)
legend("topleft",legend=c("��ʵֵ","Ԥ��ֵ"),lty=c(5:1),lwd=2,,col=c("blue","red"))
plot(as.numeric(f.p2$forecast[[1]]),princ_x[-index,1],pch="��",xlab="Ԥ��ֵ",ylab="��ʵֵ",main="Ԥ��VS��ʵ")
psse<-sqrt(mean((f.p2$forecast[[1]]-princ_x[-index,1])^2))
rse<-mean(abs((f.p2$forecast[[1]]-princ_x[-index,1])/princ_x[-index,1]))

#��ϻ��ģ�ͱȽ�
fld.bb<-estBlackBox(fld,max.lag=10)
print(fld.bb)
rr=checkResiduals(fld.bb)
f.p3<-forecast(fld.bb,conditioning.inputs.forecasts=princ_x[-index,2:5])
tfplot(f.p3)
plot(as.numeric(f.p3$forecast[[1]]),princ_x[-index,1],pch="��",xlab="Ԥ��ֵ",ylab="��ʵֵ",main="Ԥ��VS��ʵ")

tfplot(fld.ls,fld.ss,fld.bb) #������ϵıȽ�
