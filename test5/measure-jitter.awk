BEGIN {
#程序初始化
   old_time=0;
   old_seq_no=0;
   i=0;
}
{
   action = $1;
   time = $2;
   node_1 = $3;
   node_2 = $4;
   type = $5;
   flow_id = $8;
   node_1_address = $9;
   node_2_address = $10;
   seq_no = $11;
   packet_id = $12;
  
#判断是否为n2传送到n3，且封包型态为cbr，动作为接受封包
   if(node_1==2 && node_2==3 && type=="cbr" && action=="r") {
#求出目前封包的序号和上次成功接收的序号差值
	dif=seq_no-old_seq_no;

#处理第一个接收封包
        if(dif==0)  
          dif=1;

#求出jitter
      	jitter[i]=(time-old_time)/dif;
      	seq[i]=seq_no;
		i=i+1;
      	old_seq_no=seq_no;
      	old_time=time;
   }     
}
END {
   for (j=1; j <i ;j++)
    printf("%d\t%f\n",seq[j],jitter[j]);
}