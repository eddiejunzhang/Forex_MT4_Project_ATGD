目标
以往的交易，要么是从网站上得到提示、从邮件中得到信号之后进行人为操作，要么是写好程序，按固定的所谓“策略”进行操作。这两种各有优劣。前者有了灵活但缺乏耐心、纪律。后者有了纪律但不灵活。所以计划把程序与外部信息结合起来，使它们各自发挥长处，编一套半自动交易系统，这一计划命名为Tiger Project.

设计思想
这是一个交易系统，交易策略以模块的方式加进去。
总体上是将专业机构对市场的判断转化为交易指令，注入到系统中，按照既定的交易策略，进行短时，高频度交易。确保耐心、纪律的贯彻。
交易策略目前考虑采用的有：
	海豚战法
	保利加
	

软件架构

一个文本文件，把我得到的信息写进去。程序提取我的信息，进行市场操作，将过期的信息移出指令集。
我的信息包括：在某一特定时间段内，对市场的判断、下单的指令。要分为几类。
		a. 对某个货币对的趋势判断
		b. 下单的机会
		c. 下单参数，如下单量，止损位置、止赢位置、是否BE
每一类有一个标识（同时确定了顺序），有时间段的定义，
判断的格式是这样的：
	0401 1500-0402 1200 EU UpTrend
	含义是：4月1日15时至2日12时，E/U 是上升趋势
	指令的格式是这样的：
		0401 1500-0402 1200 EU BuyWhenTriggered 0.01
		
	要设计一系列函数来处理每一种指令。需要画逻辑图。
后一行指令优先。

交易规范
持仓不过周末。

软件结构
INIT
判断配置文件是否存在，如果不存在，则继续用原来的参数。
如果存在，则从配置文件中读取参数。
显示这里要占用大量内存，因为有太多参数要保存在内存中。

TIMER