# Copyright (c) 1997 Regents of the University of California.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#      This product includes software developed by the Computer Systems
#      Engineering Group at Lawrence Berkeley Laboratory.
# 4. Neither the name of the University nor of the Laboratory may be used
#    to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# wireless2.tcl
# simulation of a wired-cum-wireless scenario consisting of 2 wired nodes
# connected to a wireless domain through a base-station node.
# ======================================================================
# Define options
# ======================================================================
#pro1 opt??
set opt(chan)           Channel/WirelessChannel    ;# channel type 信道类型
set opt(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set opt(netif)          Phy/WirelessPhy            ;# network interface type
set opt(mac)            Mac/802_11                 ;# MAC type
set opt(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set opt(ll)             LL                         ;# link layer type
set opt(ant)            Antenna/OmniAntenna        ;# antenna model
set opt(ifqlen)         50                         ;# max packet in ifq
set opt(nn)             3                          ;# number of mobilenodes
set opt(adhocRouting)   DSDV                       ;# routing protocol
#pro2 opt(cp) ?? opt(sc)
set opt(cp)             ""                         ;# connection pattern file
set opt(sc)     "scen-test2"    ;                   # node movement file. 

set opt(x)      1000                            ;# x coordinate of topology
set opt(y)      1000                           ;# y coordinate of topology
set opt(seed)   0.0                            ;# seed for random number gen.
set opt(stop)   250                            ;# time to stop simulation
#pro3 下面的作用？
set opt(ftp1-start)      160.0
set opt(ftp2-start)      170.0
set num_wired_nodes      2
set num_bs_nodes         1

# ============================================================================
# check for boundary parameters and random seed
if { $opt(x) == 0 || $opt(y) == 0 } {
	puts "No X-Y boundary values given for wireless topology\n"
}
#pro4 为什么检测>0的时候
if {$opt(seed) > 0} {
	puts "Seeding Random number generator with $opt(seed)\n"
	ns-random $opt(seed)
}

# create simulator instance
set ns_   [new Simulator]

# set up for hierarchical routing
#混合网络必须采用分层路由以便能够在有线网络和无线网络之间传递数据包，ns中，有线网络是基于拓扑
#连接关系的，ns用这个连接信息在节点之间传递转发表，而无线中没有链路的概念，数据包在无线拓扑中根
#据adhoc路由选路，这种路由根据相邻之间传递的路由请求建立转发表，如果要在无线和有线之间建立连接
#必须要用到基站作为网关，通过分层拓扑结构定义了域和子域
$ns_ node-config -addressType hierarchical
AddrParams set domain_num_ 2           ;# number of domains
lappend cluster_num 2 1                ;# number of clusters in each domain
AddrParams set cluster_num_ $cluster_num
lappend eilastlevel 1 1 4              ;# number of nodes in each cluster 
AddrParams set nodes_num_ $eilastlevel ;# of each domain
#以上意思是，有两个域，域中节点定于数分别是2,1，第一个域有两个簇，第二个域有一个簇。1 1 4代表，前面两个
#簇中每个簇有一个节点，第三个簇中有4个节点
set tracefd  [open test.tr w]  ;#跟踪对象,数据都输出到test.tr里面
set namtrace [open test.nam w]
$ns_ trace-all $tracefd
#pro6 下面这段代码作用？
$ns_ namtrace-all-wireless $namtrace $opt(x) $opt(y)


set f0 [open tcp1_rtt.tr w]
set f1 [open tcp2_rtt.tr w]

# Create topography object
set topo   [new Topography]

# define topology
#设置移动场景范围
$topo load_flatgrid $opt(x) $opt(y)

# create God
# GOD可以记录网络中所有的节点信息和邻居信息
#pro7为什么要这样写呢？？
create-god [expr $opt(nn) + $num_bs_nodes]
#  pro8 下面这两句是什么意思？
#create wired nodes
set temp {0.0.0 0.1.0}        ;# hierarchical addresses for wired domain
for {set i 0} {$i < $num_wired_nodes} {incr i} {
    set W($i) [$ns_ node [lindex $temp $i]] 
}

# configure for base-station node
$ns_ node-config -adhocRouting $opt(adhocRouting) \
                 -llType $opt(ll) \
                 -macType $opt(mac) \
                 -ifqType $opt(ifq) \
                 -ifqLen $opt(ifqlen) \
                 -antType $opt(ant) \
                 -propType $opt(prop) \
                 -phyType $opt(netif) \
                 -channelType $opt(chan) \
		 -topoInstance $topo \
                 -wiredRouting ON \
		 -agentTrace ON \
                 -routerTrace ON \
                 -macTrace OFF 

#create base-station node
set temp {1.0.0 1.0.1 1.0.2 1.0.3}   ;# hier address to be used for wireless
                                     ;# domain
set BS(0) [$ns_ node [lindex $temp 0]]
$BS(0) random-motion 0               ;# disable random motion

#provide some co-ord (fixed) to base station node
$BS(0) set X_ 250.0
$BS(0) set Y_ 200.0
$BS(0) set Z_ 0.0

# create mobilenodes in the same domain as BS(0)  
# note the position and movement of mobilenodes is as defined
# in $opt(sc)

#configure for mobilenodes
$ns_ node-config -wiredRouting OFF

  for {set j 0} {$j < $opt(nn)} {incr j} {
    set node_($j) [ $ns_ node [lindex $temp \
	    [expr $j+1]] ]
    $node_($j) base-station [AddrParams addr2id \
	    [$BS(0) node-addr]]
}

#create links between wired and BS nodes

$ns_ duplex-link $W(0) $W(1) 5Mb 20ms DropTail
$ns_ duplex-link $W(1) $BS(0) 5Mb 20ms DropTail

$ns_ duplex-link-op $W(0) $W(1) orient right-down
$ns_ duplex-link-op $W(1) $BS(0) orient right

#pro9 下面这段代码作用？
$ns_ queue-limit $W(1) $BS(0) 10

$ns_ at 0.0 "$node_(0) label Client"
$ns_ at 0.0 "$node_(1) label Client"
$ns_ at 0.0 "$node_(2) label Client"


$ns_ at 0.0 "$W(0) label Server"

$ns_ at 0.0 "$W(1) label Route"

$ns_ at 0.0 "$BS(0) label BS"

# setup TCP connections
#pro9 简单介绍一下，下面的两部分代码
set tcp1 [new Agent/TCP/Vegas]
$tcp1 set class_ 1
set sink1 [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp1
$ns_ attach-agent $W(0) $sink1
$ns_ connect $tcp1 $sink1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$tcp1 set fid_ 1
$ns_ at $opt(ftp1-start) "$ftp1 start"

set tcp2 [new Agent/TCP/Vegas]
$tcp2 set class_ 2
set sink2 [new Agent/TCPSink]
$ns_ attach-agent $W(0) $tcp2
$ns_ attach-agent $node_(2) $sink2
$ns_ connect $tcp2 $sink2
set ftp2 [new Application/FTP]
$tcp2 set fid_ 2
$ftp2 attach-agent $tcp2
$ns_ at $opt(ftp2-start) "$ftp2 start"


# source connection-pattern and node-movement scripts
if { $opt(cp) == "" } {
	puts "*** NOTE: no connection pattern specified."
        set opt(cp) "none"
} else {
	puts "Loading connection pattern..."
	source $opt(cp)
}
if { $opt(sc) == "" } {
	puts "*** NOTE: no scenario file specified."
        set opt(sc) "none"
} else {
	puts "Loading scenario file..."
	source $opt(sc)
	puts "Load complete..."
}

# Define initial node position in nam

for {set i 0} {$i < $opt(nn)} {incr i} {

    # 20 defines the node size in nam, must adjust it according to your
    # scenario
    # The function must be called after mobility model is defined

    $ns_ initial_node_pos $node_($i) 20
}     
#pro10 记录的内容放到哪了？
proc record {} {
  global ns_ f0 f1 tcp1 tcp2
	set now [$ns_ now]
	puts $f0 "$now [$tcp1 set v_rtt_]"
	puts $f1 "$now [$tcp2 set v_rtt_]"
	$ns_ at [expr $now+0.01] "record"
}


proc finish {} {
global ns_ nf nd f0 f1
     $ns flush-trace
    close $f0
        close $f1
        exec nam out.nam &
        exit 0
}

$ns_ at  0.0 "record"

# Tell all nodes when the simulation ends
for {set i } {$i < $opt(nn) } {incr i} {
    $ns_ at $opt(stop).0 "$node_($i) reset";
}
$ns_ at $opt(stop).0 "$BS(0) reset";

$ns_ at $opt(stop).0002 "puts \"NS EXITING...\" ; $ns_ halt"
$ns_ at $opt(stop).0001 "stop"
proc stop {} {
    global ns_ tracefd namtrace
#    $ns_ flush-trace
    close $tracefd
    close $namtrace
}

# informative headers for CMUTracefile
puts $tracefd "M 0.0 nn $opt(nn) x $opt(x) y $opt(y) rp \
	$opt(adhocRouting)"
puts $tracefd "M 0.0 sc $opt(sc) cp $opt(cp) seed $opt(seed)"
puts $tracefd "M 0.0 prop $opt(prop) ant $opt(ant)"

puts "Starting Simulation..."
$ns_ run

