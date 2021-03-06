

#######################################################
#######################################################
##
## 名称：《R语言数据分析·关联》
## 作者：艾新波
## 学校：北京邮电大学
## 版本：V8
## 时间：2018年3月
##
##*****************************************************
##
## ch05_Association Rules_V8
## Data Analytics with R
## Instructed by Xinbo Ai
## Beijing University of Posts and Telecommunications
##
##*****************************************************
##
## Author: byaxb
## Email:axb@bupt.edu.cn
## QQ:23127789
## WeChat:13641159546
## URL:https://github.com/byaxb
##
##*****************************************************
##
## (c)2012~2018
##
#######################################################
#######################################################


#在观察完数据的长相之后，便开始深入其内在的关系结构了
#本次实验聚焦的是伴随关系
#教材上的名称频繁项集、关联规则
#关联规则可能是机器学习/数据挖掘领域最为知名的算法了
#啤酒和尿不湿的故事，提供了“发现数据背后意想不到的模式”
#的范本，也让关联规则成为数据挖掘最好的
#科（guang）普（gao）

#######################################################
##数据读取与类型转换
#######################################################
#清空内存
rm(list = ls())
library(tidyverse)
library(readr)
cjb_url <-"https://github.com/byaxb/RDataAnalytics/raw/master/data/cjb.csv"

cjb <- read_csv(cjb_url,
                locale = locale(encoding = "CP936"))

#对数据进行简单描述
str(cjb)
#> Classes ‘tbl_df’, ‘tbl’ and 'data.frame':	775 obs. of  13 variables:
#> $ xm  : chr  "周黎" "汤海明" "舒江辉" "翁柯" ...
#> $ bj  : int  1101 1101 1101 1101 1101 1101 1101 1101 1101 1101 ...
#> $ xb  : chr  "女" "男" "男" "女" ...
#> $ yw  : int  94 87 92 91 85 92 88 81 88 94 ...
#> $ sx  : int  82 94 79 84 92 82 72 89 77 81 ...
#> $ wy  : int  96 89 86 96 82 85 86 87 95 88 ...
#> $ zz  : int  97 95 98 93 93 91 94 97 94 91 ...
#> $ ls  : int  97 94 95 97 87 90 87 94 84 85 ...
#> $ dl  : int  98 94 96 94 88 92 88 96 94 98 ...
#> $ wl  : int  95 90 89 82 95 82 89 81 87 81 ...
#> $ hx  : int  94 90 94 90 94 98 98 88 94 88 ...
#> $ sw  : int  88 89 87 83 93 90 94 83 82 88 ...
#> $ wlfk: chr  "文科" "文科" "文科" "文科" ...

summary(cjb)
#> xm                  bj            xb           
#> Length:775         Min.   :1101   Length:775        
#> Class :character   1st Qu.:1104   Class :character  
#> Mode  :character   Median :1107   Mode  :character  
#> Mean   :1108                     
#> 3rd Qu.:1111                     
#> Max.   :1115                     
#> yw              sx               wy      
#> Min.   : 0.00   Min.   :  0.00   Min.   : 0.0  
#> 1st Qu.:85.00   1st Qu.: 81.00   1st Qu.:84.0  
#> Median :88.00   Median : 89.00   Median :88.0  
#> Mean   :87.27   Mean   : 86.08   Mean   :87.4  
#> 3rd Qu.:91.00   3rd Qu.: 95.00   3rd Qu.:92.0  
#> Max.   :96.00   Max.   :100.00   Max.   :99.0  
#> zz               ls               dl        
#> Min.   :  0.00   Min.   :  0.00   Min.   :  0.00  
#> 1st Qu.: 90.00   1st Qu.: 85.00   1st Qu.: 90.00  
#> Median : 93.00   Median : 90.00   Median : 94.00  
#> Mean   : 92.21   Mean   : 89.03   Mean   : 92.91  
#> 3rd Qu.: 95.00   3rd Qu.: 94.50   3rd Qu.: 96.00  
#> Max.   :100.00   Max.   :100.00   Max.   :100.00  
#> wl              hx               sw        
#> Min.   :  0.0   Min.   :  0.00   Min.   :  0.00  
#> 1st Qu.: 74.0   1st Qu.: 88.00   1st Qu.: 81.00  
#> Median : 83.0   Median : 94.00   Median : 88.00  
#> Mean   : 81.1   Mean   : 91.57   Mean   : 86.26  
#> 3rd Qu.: 91.0   3rd Qu.: 98.00   3rd Qu.: 93.00  
#> Max.   :100.0   Max.   :100.00   Max.   :100.00  
#> wlfk          
#> Length:775        
#> Class :character  
#> Mode  :character  

View(cjb)
library(Hmisc)
describe(cjb)

#数据离散化
#arules包只能对离散数据进行关联规则挖掘
#离散化有专用的包discretization
#当然，对于大部分的任务而言，
#cut()函数已经够用了
as_five_grade_scores <- function(x) {
  cut(x, 
      breaks = c(0, seq(60, 100, 10)),
      labels = c("不及格", "及格", "中", "良", "优"),
      include.lowest = TRUE, 
      ordered_result = TRUE)
}

cjb %<>%
  mutate_at(vars(xb, wlfk), factor) %>% #类型转换
  mutate_at(vars(yw:sw), as_five_grade_scores) %>%#数据分箱
  select(-(1:2))
#> Classes ‘tbl_df’, ‘tbl’ and 'data.frame':	775 obs. of  11 variables:
#> $ xb  : Factor w/ 2 levels "男","女": 2 1 1 2 1 2 2 1 2 2 ...
#> $ yw  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 4 5 5 4 5 4 4 4 5 ...
#> $ sx  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 4 5 3 4 5 4 3 4 3 4 ...
#> $ wy  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 4 4 5 4 4 4 4 5 4 ...
#> $ zz  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 5 5 5 5 5 5 5 5 5 ...
#> $ ls  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 5 5 5 4 4 4 5 4 4 ...
#> $ dl  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 5 5 5 4 5 4 5 5 5 ...
#> $ wl  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 4 4 4 5 4 4 4 4 4 ...
#> $ hx  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 4 5 4 5 5 5 4 5 4 ...
#> $ sw  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 4 4 4 4 5 4 5 4 4 4 ...
#> $ wlfk: Factor w/ 2 levels "理科","文科": 2 2 2 2 2 2 2 2 2 2 ...


View(cjb)
#对转换后的数据进行简单描述
str(cjb)
#> Classes ‘tbl_df’, ‘tbl’ and 'data.frame':	775 obs. of  11 variables:
#> $ xb  : Factor w/ 2 levels "男","女": 2 1 1 2 1 2 2 1 2 2 ...
#> $ yw  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 4 5 5 4 5 4 4 4 5 ...
#> $ sx  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 4 5 3 4 5 4 3 4 3 4 ...
#> $ wy  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 4 4 5 4 4 4 4 5 4 ...
#> $ zz  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 5 5 5 5 5 5 5 5 5 ...
#> $ ls  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 5 5 5 4 4 4 5 4 4 ...
#> $ dl  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 5 5 5 4 5 4 5 5 5 ...
#> $ wl  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 4 4 4 5 4 4 4 4 4 ...
#> $ hx  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 5 4 5 4 5 5 5 4 5 4 ...
#> $ sw  : Ord.factor w/ 5 levels "不及格"<"及格"<..: 4 4 4 4 5 4 5 4 4 4 ...
#> $ wlfk: Factor w/ 2 levels "理科","文科": 2 2 2 2 2 2 2 2 2 2 ...

summary(cjb)
library(Hmisc)
describe(cjb)

library(arules)
#转换为transaction
cjb_trans <- as(cjb, "transactions")
#查看数据
cjb_trans
#> transactions in sparse format with
#> 775 transactions (rows) and
#> 49 items (columns)

inspect(cjb_trans[1:5])
#> items       transactionID
#> [1] {xb=女,                  
#> yw=优,                  
#> sx=良,                  
#> wy=优,                  
#> zz=优,                  
#> ls=优,                  
#> dl=优,                  
#> wl=优,                  
#> hx=优,                  
#> sw=良,                  
#> wlfk=文科}             1
#> [2] {xb=男,                  
#> yw=良,                  
#> sx=优,                  
#> wy=良,                  
#> zz=优,                  
#> ls=优,                  
#> dl=优,                  
#> wl=良,                  
#> hx=良,                  
#> sw=良,                  
#> wlfk=文科}             2

#转换为数据框
cjb_trans %>%
  as("data.frame") %>%
  View()
#转换为矩阵
cjb_trans %>%
  as("matrix") %>%
  View()
#转换为列表
cjb_trans %>%
  as("list") %>%
  head(n = 2)
#无论是列表、矩阵、数据框
#还是最直接的事务记录transactions
#都可以直接用来挖掘

#######################################################
##关联规则挖掘
#######################################################
#关于Apriori算法的原理，请参阅课程讲义
#R中的具体实现，则简单得超乎人们的想象
#首先是加载包
#对于关联规则的挖掘和可视化
#主要用arules和arulesViz两个包
#加载后者时，前者自动加载
library(arulesViz)
#调用apriori()函数进行挖掘
irules_args_default <- apriori(cjb_trans)
#> Apriori
#> 
#> Parameter specification:
#>   confidence minval smax arem  aval originalSupport
#> 0.8    0.1    1 none FALSE            TRUE
#> maxtime support minlen maxlen target   ext
#> 5     0.1      1     10  rules FALSE
#> 
#> Algorithmic control:
#>   filter tree heap memopt load sort verbose
#> 0.1 TRUE TRUE  FALSE TRUE    2    TRUE
#> 
#> Absolute minimum support count: 77 
#> 
#> set item appearances ...[0 item(s)] done [0.00s].
#> set transactions ...[49 item(s), 775 transaction(s)] done [0.00s].
#> sorting and recoding items ... [27 item(s)] done [0.00s].
#> creating transaction tree ... done [0.00s].
#> checking subsets of size 1 2 3 4 5 6 7 8 done [0.00s].
#> writing ... [2097 rule(s)] done [0.00s].
#> creating S4 object  ... done [0.00s].

#看一看挖出来的规则
irules_args_default
#> set of 2097 rules

#查看具体的规则
inspect(irules_args_default[1:3])
#> lhs        rhs         support   confidence
#> [1] {wl=优} => {sx=优}     0.2141935 0.8258706 
#> [2] {wl=优} => {wlfk=理科} 0.2090323 0.8059701 
#> [3] {wl=优} => {hx=优}     0.2425806 0.9353234 
#> lift     count
#> [1] 1.808050 166  
#> [2] 1.639441 162  
#> [3] 1.510158 188 

#关于规则的一些基本信息
irules_args_default@info
#> $`data`
#> cjb_trans
#> 
#> $ntransactions
#> [1] 775
#> 
#> $support
#> [1] 0.1
#> 
#> $confidence
#> [1] 0.8

######################################################
##参数设定
#######################################################
#定制其中的参数
#设置支持度、置信度、最小长度等
irules <- apriori(
  cjb_trans,
  parameter = list(
    minlen = 2,
    supp = 50 / length(cjb_trans), #最小支持度，减少偶然性
    conf = 0.8 #最小置信度，推断能力
  ))
length(irules)
#> [1] 5584

#计算一下不同的支持度、置信度的结果
sup_series <- nrow(cjb):1
conf_series <- seq(1,0.01, by = -0.05)
len_matrix <- matrix(ncol = length(sup_series),
                     nrow = length(conf_series))
sup_conf <- expand.grid(sup_series, conf_series) %>%
  set_names(c("support", "confidence"))
nrow(sup_conf)
head(sup_conf)
#根据配置不同，以下代码可能需要运行几分钟
sup_conf$nrules <- apply(sup_conf, 1, function(cur_sup_conf) {
  irules <- apriori(
    cjb_trans,
    parameter = list(
      minlen = 2,
      supp = cur_sup_conf["support"] / length(cjb_trans), #最小支持度，减少偶然性
      conf = cur_sup_conf["confidence"] #最小置信度，推断能力
    ),
    control =  list(verbose = FALSE))
  return(length(irules))
})

library(tidyverse)
sup_conf %>%
  filter(support %% 20 == 0) %>%
  ggplot(aes(x = confidence, y = support, fill = log10(nrules))) +
  geom_tile()

#也可以进一步设定前项和后项
irules <- apriori(
  cjb_trans,
  parameter = list(
    minlen = 2,
    supp = 50 / length(cjb_trans),
    conf = 0.8
  ),
  appearance = list(rhs = paste0("wlfk=", c("文科", "理科")),
                    default = "lhs"))

#对规则进行排序
irules_sorted <- sort(irules, by = "lift")
inspect(irules_sorted[1:10])
inspectDT(irules_sorted)

#######################################################
##删除冗余规则
#######################################################
subset.matrix <-
  is.subset(irules_sorted, irules_sorted, sparse = FALSE)
subset.matrix[lower.tri(subset.matrix, diag = TRUE)] <- NA
redundant <- colSums(subset.matrix, na.rm = TRUE) >= 1
as.integer(which(redundant))
#> [1]   3   5   6   7   8  13  14  15  19  22  23  25
#> [13]  26  27  29  30  31  34  38  39  40  41  44  45
#> [25]  46  47  48  49  50  52  53  54  56  58  61  62
#> [37]  63  64  65  66  67  68  69  70  71  75  77  78
#> [49]  81  83  84  86  87  89  90  91  94  95  96  97
#> [61]  99 101 103 104 107 109 110 111 113 115 116 117
#> [73] 119 121 123 124 125 126 127 128 131 132 133 135
#> [85] 136 140 142 144 145 146 147 148 149 150 152 154
#> [97] 156 157 159 161 162 163 164 165 166 167 168 169
#> [109] 170 171 173 174 175 179 180 181 183 186 188 189
#> [121] 190 191 193 194 195 196 197 198 199 200 201 202
#> [133] 203 204 205 207 208 211 212 214 215 217 218 219
#> [145] 220 222 223 224 225 226 227 228 229 230 231 232
#> [157] 234 235 236 237 238 239 240 241 242 243 244 245
#> [169] 246 247 248 249 250 251 252 253 255 256 258 259
#> [181] 260 261 263 264 265 266 267 268 270 272 273 274
#> [193] 275 276 277 278 279 282 283 284 286 287 288 289
#> [205] 290 291 293 294 296 297 298 299 300 301 304 305
#> [217] 306 307 308 309 310 312 313 316 319 321 322 323
#> [229] 324 326 327 328 331 333 335 336 337 338 339 340
#> [241] 341 343 344 345 348 351 352 353 354 356 357 360
#> [253] 361 362 363 364 366 367 368 369 370 372 373 374
#> [265] 375 376 377 378 379 380 381 383 385 388 389 390
#> [277] 391 392 393 394

(irules_pruned <- irules_sorted[!redundant])
#> set of 57 rules 
inspect(irules_pruned)
inspectDT(irules_pruned)
#当然，很多时候，我们只想查看其中部分规则
inspect(head(irules_pruned))
inspect(tail(irules_pruned))



#######################################################
##评估指标
#######################################################
#查看评估指标
quality(irules_pruned)
#> support confidence     lift count
#> 331 0.07354839  0.9344262 1.900736    57
#> 334 0.09032258  0.9333333 1.898513    70
#> 229 0.09935484  0.9277108 1.887076    77
#> 212 0.09161290  0.9220779 1.875618    71
#> 213 0.09032258  0.9210526 1.873532    70
#> 256 0.10451613  0.9204545 1.872316    81
#> 211 0.07354839  0.9193548 1.870079    57
#> 21  0.06967742  0.9473684 1.863478    54
#> 242 0.06838710  0.9137931 1.858765    53
#> 258 0.06838710  0.9137931 1.858765    53
#> 124 0.10838710  0.9130435 1.857241    84
#> 225 0.08129032  0.9130435 1.857241    63
#> 126 0.10580645  0.9111111 1.853310    82
#> 91  0.09161290  0.9102564 1.851571    71
#> 98  0.10064516  0.9069767 1.844900    78
#> 100 0.10064516  0.9069767 1.844900    78
#> 8   0.07483871  0.9062500 1.843422    58
#> 40  0.10967742  0.9042553 1.839364    85
#> 276 0.07225806  0.9032258 1.837270    56
#> 119 0.06967742  0.9000000 1.830709    54
#> 143 0.11612903  0.9000000 1.830709    90
#> 155 0.07870968  0.8970588 1.824726    61
#> 216 0.06709677  0.8965517 1.823694    52
#> 294 0.11096774  0.8958333 1.822233    86
#> 181 0.06580645  0.8947368 1.820003    51
#> 200 0.06580645  0.8947368 1.820003    51
#> 351 0.07354839  0.8906250 1.811639    57
#> 222 0.08258065  0.8888889 1.808107    64
#> 238 0.09290323  0.8888889 1.808107    72
#> 30  0.10193548  0.8876404 1.805568    79
#> 47  0.12129032  0.8867925 1.803843    94
#> 49  0.12000000  0.8857143 1.801650    93
#> 206 0.06967742  0.8852459 1.800697    54
#> 136 0.09806452  0.8837209 1.797595    76
#> 94  0.08774194  0.8831169 1.796366    68
#> 43  0.10709677  0.8829787 1.796085    83
#> 163 0.11612903  0.8823529 1.794812    90
#> 233 0.07612903  0.8805970 1.791241    59
#> 165 0.11354839  0.8800000 1.790026    88
#> 6   0.09032258  0.9090909 1.788186    70
#> 220 0.14838710  0.8778626 1.785679   115
#> 11  0.12903226  0.8771930 1.784316   100
#> 236 0.07354839  0.8769231 1.783767    57
#> 93  0.15354839  0.8750000 1.779856   119
#> 153 0.07225806  0.8750000 1.779856    56
#> 107 0.09806452  0.8735632 1.776933    76
#> 108 0.16000000  0.8732394 1.776274   124
#> 307 0.08000000  0.8732394 1.776274    62
#> 95  0.14838710  0.8712121 1.772151   115
#> 88  0.06967742  0.8709677 1.771654    54
#> 314 0.09548387  0.8705882 1.770882    74
#> 70  0.08645161  0.8701299 1.769949    67
#> 110 0.09419355  0.8690476 1.767748    73
#> 29  0.15354839  0.8686131 1.766864   119
#> 63  0.11870968  0.8679245 1.765463    92
#> 103 0.07612903  0.8676471 1.764899    59
#> 32  0.16516129  0.8648649 1.759240   128
#> 42  0.18064516  0.8641975 1.757882   140
#> 279 0.09032258  0.8641975 1.757882    70
#> 174 0.08129032  0.8630137 1.755474    63
#> 178 0.08903226  0.8625000 1.754429    69
#> 59  0.07870968  0.8591549 1.747625    61
#> 34  0.16258065  0.8571429 1.743532   126
#> 72  0.07741935  0.8571429 1.743532    60
#> 73  0.09290323  0.8571429 1.743532    72
#> 33  0.09935484  0.8555556 1.740303    77
#> 159 0.09935484  0.8555556 1.740303    77
#> 10  0.18322581  0.8554217 1.740031   142
#> 61  0.06838710  0.8548387 1.738845    53
#> 154 0.09032258  0.8536585 1.736445    70
#> 187 0.13935484  0.8503937 1.729803   108
#> 57  0.07483871  0.8787879 1.728580    58
#> 9   0.16774194  0.8496732 1.728338   130
#> 186 0.10838710  0.8484848 1.725921    84
#> 171 0.13677419  0.8480000 1.724934   106
#> 177 0.06451613  0.8474576 1.723831    50
#> 167 0.12645161  0.8448276 1.718481    98
#> 175 0.08129032  0.8400000 1.708661    63
#> 60  0.10064516  0.8387097 1.706037    78
#> 56  0.06709677  0.8666667 1.704738    52
#> 68  0.09161290  0.8352941 1.699089    71
#> 1   0.06451613  0.8620690 1.695694    50
#> 4   0.07225806  0.8615385 1.694651    56
#> 75  0.15354839  0.8321678 1.692730   119
#> 71  0.07612903  0.8309859 1.690326    59
#> 168 0.11354839  0.8301887 1.688704    88
#> 12  0.06838710  0.8281250 1.684506    53
#> 66  0.14193548  0.8270677 1.682355   110
#> 64  0.12903226  0.8264463 1.681092   100
#> 150 0.10967742  0.8252427 1.678643    85
#> 24  0.07225806  0.8235294 1.675158    56
#> 65  0.14451613  0.8235294 1.675158   112
#> 67  0.08387097  0.8227848 1.673644    65
#> 7   0.09548387  0.8505747 1.673085    74
#> 121 0.07741935  0.8219178 1.671880    60
#> 62  0.06451613  0.8196721 1.667312    50
#> 58  0.09290323  0.8470588 1.666169    72
#> 53  0.18580645  0.8181818 1.664281   144
#> 54  0.11483871  0.8165138 1.660888    89
#> 39  0.08000000  0.8157895 1.659414    62
#> 27  0.07354839  0.8142857 1.656355    57
#> 52  0.11870968  0.8141593 1.656098    92
#> 13  0.19741935  0.8138298 1.655428   153
#> 18  0.07870968  0.8133333 1.654418    61
#> 20  0.10064516  0.8125000 1.652723    78
#> 14  0.12774194  0.8114754 1.650639    99
#> 180 0.07741935  0.8108108 1.649287    60
#> 23  0.08258065  0.8101266 1.647895    64
#> 69  0.09290323  0.8089888 1.645581    72
#> 2   0.20903226  0.8059701 1.639441   162
#> 188 0.10580645  0.8039216 1.635274    82
#> 189 0.06838710  0.8030303 1.633461    53
#> 19  0.15096774  0.8013699 1.630083   117
#> 3   0.06838710  0.8281250 1.628926    53
#> 5   0.07870968  0.8133333 1.599831    61
#> 55  0.07741935  0.8108108 1.594869    60
#> 17  0.12516129  0.8083333 1.589996    97
#> 312 0.06451613  0.8064516 1.586294    50
#> 184 0.06838710  0.8030303 1.579565    53
#> 16  0.08258065  0.8000000 1.573604    64
#> 74  0.08258065  0.8000000 1.573604    64

str(quality(irules_pruned))
#> 'data.frame':	121 obs. of  4 variables:
#> $ support   : num  0.0735 0.0903 0.0994 0.0916 0.0903 ...
#> $ confidence: num  0.934 0.933 0.928 0.922 0.921 ...
#> $ lift      : num  1.9 1.9 1.89 1.88 1.87 ...
#> $ count     : num  57 70 77 71 70 81 57 54 53 53 ...

#更多评估指标
(more_measures <- interestMeasure(
  irules_pruned,
  measure = c("support", "confidence", "lift","casualConfidence"),
  transactions = cjb_trans))
#> support confidence     lift casualConfidence
#> 1   0.07354839  0.9344262 1.900736        0.9999018
#> 2   0.09032258  0.9333333 1.898513        0.9998970
#> 3   0.09935484  0.9277108 1.887076        0.9998864
#> 4   0.09161290  0.9220779 1.875618        0.9998791
#> 5   0.09032258  0.9210526 1.873532        0.9998778
#> 6   0.10451613  0.9204545 1.872316        0.9998737
#> 7   0.07354839  0.9193548 1.870079        0.9998790
#> 8   0.06967742  0.9473684 1.863478        0.9999223
#> 9   0.06838710  0.9137931 1.858765        0.9998718
#> 10  0.06838710  0.9137931 1.858765        0.9998718
#> 11  0.10838710  0.9130435 1.857241        0.9998607
#> 12  0.08129032  0.9130435 1.857241        0.9998675
#> 13  0.10580645  0.9111111 1.853310        0.9998582
#> 14  0.09161290  0.9102564 1.851571        0.9998605
#> 15  0.10064516  0.9069767 1.844900        0.9998529
#> 16  0.10064516  0.9069767 1.844900        0.9998529
#> 17  0.07483871  0.9062500 1.843422        0.9998587
#> 18  0.10967742  0.9042553 1.839364        0.9998460
#> 19  0.07225806  0.9032258 1.837270        0.9998548
#> 20  0.06967742  0.9000000 1.830709        0.9998506
#> 21  0.11612903  0.9000000 1.830709        0.9998371
#> 22  0.07870968  0.8970588 1.824726        0.9998435
#> 23  0.06709677  0.8965517 1.823694        0.9998462
#> 24  0.11096774  0.8958333 1.822233        0.9998317
#> 25  0.06580645  0.8947368 1.820003        0.9998439
#> 26  0.06580645  0.8947368 1.820003        0.9998439
#> 27  0.07354839  0.8906250 1.811639        0.9998352
#> 28  0.08258065  0.8888889 1.808107        0.9998295
#> 29  0.09290323  0.8888889 1.808107        0.9998262
#> 30  0.10193548  0.8876404 1.805568        0.9998212
#> 31  0.12129032  0.8867925 1.803843        0.9998133
#> 32  0.12000000  0.8857143 1.801650        0.9998119
#> 33  0.06967742  0.8852459 1.800697        0.9998282
#> 34  0.09806452  0.8837209 1.797595        0.9998161
#> 35  0.08774194  0.8831169 1.796366        0.9998187
#> 36  0.10709677  0.8829787 1.796085        0.9998118
#> 37  0.11612903  0.8823529 1.794812        0.9998076
#> 38  0.07612903  0.8805970 1.791241        0.9998188
#> 39  0.11354839  0.8800000 1.790026        0.9998045
#> 40  0.09032258  0.9090909 1.788186        0.9998598
#> 41  0.14838710  0.8778626 1.785679        0.9997882
#> 42  0.12903226  0.8771930 1.784316        0.9997941
#> 43  0.07354839  0.8769231 1.783767        0.9998141
#> 44  0.15354839  0.8750000 1.779856        0.9997811
#> 45  0.07225806  0.8750000 1.779856        0.9998116
#> 46  0.09806452  0.8735632 1.776933        0.9997996
#> 47  0.16000000  0.8732394 1.776274        0.9997755
#> 48  0.08000000  0.8732394 1.776274        0.9998060
#> 49  0.14838710  0.8712121 1.772151        0.9997762
#> 50  0.06967742  0.8709677 1.771654        0.9998064
#> 51  0.09548387  0.8705882 1.770882        0.9997958
#> 52  0.08645161  0.8701299 1.769949        0.9997986
#> 53  0.09419355  0.8690476 1.767748        0.9997938
#> 54  0.15354839  0.8686131 1.766864        0.9997695
#> 55  0.11870968  0.8679245 1.765463        0.9997822
#> 56  0.07612903  0.8676471 1.764899        0.9997987
#> 57  0.16516129  0.8648649 1.759240        0.9997579
#> 58  0.18064516  0.8641975 1.757882        0.9997503
#> 59  0.09032258  0.8641975 1.757882        0.9997875
#> 60  0.08129032  0.8630137 1.755474        0.9997894
#> 61  0.08903226  0.8625000 1.754429        0.9997853
#> 62  0.07870968  0.8591549 1.747625        0.9997844
#> 63  0.16258065  0.8571429 1.743532        0.9997445
#> 64  0.07741935  0.8571429 1.743532        0.9997818
#> 65  0.09290323  0.8571429 1.743532        0.9997750
#> 66  0.09935484  0.8555556 1.740303        0.9997696
#> 67  0.09935484  0.8555556 1.740303        0.9997696
#> 68  0.18322581  0.8554217 1.740031        0.9997322
#> 69  0.06838710  0.8548387 1.738845        0.9997822
#> 70  0.09032258  0.8536585 1.736445        0.9997705
#> 71  0.13935484  0.8503937 1.729803        0.9997426
#> 72  0.07483871  0.8787879 1.728580        0.9998174
#> 73  0.16774194  0.8496732 1.728338        0.9997281
#> 74  0.10838710  0.8484848 1.725921        0.9997537
#> 75  0.13677419  0.8480000 1.724934        0.9997395
#> 76  0.06451613  0.8474576 1.723831        0.9997727
#> 77  0.12645161  0.8448276 1.718481        0.9997388
#> 78  0.08129032  0.8400000 1.708661        0.9997529
#> 79  0.10064516  0.8387097 1.706037        0.9997411
#> 80  0.06709677  0.8666667 1.704738        0.9998018
#> 81  0.09161290  0.8352941 1.699089        0.9997401
#> 82  0.06451613  0.8620690 1.695694        0.9997958
#> 83  0.07225806  0.8615385 1.694651        0.9997919
#> 84  0.15354839  0.8321678 1.692730        0.9997022
#> 85  0.07612903  0.8309859 1.690326        0.9997413
#> 86  0.11354839  0.8301887 1.688704        0.9997199
#> 87  0.06838710  0.8281250 1.684506        0.9997410
#> 88  0.14193548  0.8270677 1.682355        0.9996990
#> 89  0.12903226  0.8264463 1.681092        0.9997049
#> 90  0.10967742  0.8252427 1.678643        0.9997135
#> 91  0.07225806  0.8235294 1.675158        0.9997317
#> 92  0.14451613  0.8235294 1.675158        0.9996910
#> 93  0.08387097  0.8227848 1.673644        0.9997239
#> 94  0.09548387  0.8505747 1.673085        0.9997646
#> 95  0.07741935  0.8219178 1.671880        0.9997262
#> 96  0.06451613  0.8196721 1.667312        0.9997301
#> 97  0.09290323  0.8470588 1.666169        0.9997601
#> 98  0.18580645  0.8181818 1.664281        0.9996570
#> 99  0.11483871  0.8165138 1.660888        0.9996955
#> 100 0.08000000  0.8157895 1.659414        0.9997149
#> 101 0.07354839  0.8142857 1.656355        0.9997163
#> 102 0.11870968  0.8141593 1.656098        0.9996891
#> 103 0.19741935  0.8138298 1.655428        0.9996412
#> 104 0.07870968  0.8133333 1.654418        0.9997117
#> 105 0.10064516  0.8125000 1.652723        0.9996971
#> 106 0.12774194  0.8114754 1.650639        0.9996788
#> 107 0.07741935  0.8108108 1.649287        0.9997085
#> 108 0.08258065  0.8101266 1.647895        0.9997042
#> 109 0.09290323  0.8089888 1.645581        0.9996960
#> 110 0.20903226  0.8059701 1.639441        0.9996176
#> 111 0.10580645  0.8039216 1.635274        0.9996793
#> 112 0.06838710  0.8030303 1.633461        0.9997018
#> 113 0.15096774  0.8013699 1.630083        0.9996455
#> 114 0.06838710  0.8281250 1.628926        0.9997422
#> 115 0.07870968  0.8133333 1.599831        0.9997133
#> 116 0.07741935  0.8108108 1.594869        0.9997100
#> 117 0.12516129  0.8083333 1.589996        0.9996774
#> 118 0.06451613  0.8064516 1.586294        0.9997110
#> 119 0.06838710  0.8030303 1.579565        0.9997033
#> 120 0.08258065  0.8000000 1.573604        0.9996895
#> 121 0.08258065  0.8000000 1.573604        0.9996895

quality(irules_pruned) <- more_measures %>%
  mutate_at(
    vars(1:3), 
    funs(round(., digits = 2)))


#######################################################
##规则搜索
#######################################################
#比如仅关心文科相关的规则
irules_sub1 <- subset(irules_pruned,
                      items %in% c("wlfk=文科"))
inspect(irules_sub1)
inspectDT(irules_sub1)

irules_sub2 <- subset(irules_pruned,
                      items %pin% c("文科"))
inspectDT(irules_sub2)
#当然也可以同时满足多种搜索条件
#比如性别和确信度
irules_sub3 <- subset(irules_pruned, 
                      lhs %pin% c("xb") &
                        lift > 1.8)
inspect(irules_sub3)
inspectDT(irules_sub3)

#######################################################
##频繁项集与关联规则
#######################################################
#从规则中提取频繁项集
itemsets <- unique(generatingItemsets(irules_pruned))
itemsets
#> set of 121 itemsets
itemsets_df <- as(itemsets, "data.frame")
View(itemsets_df)
inspect(itemsets)

#反过来，先挖掘频繁项集
#再导出关联规则
#生成频繁项集，而不是规则
itemsets <- apriori(cjb_trans,
                    parameter = list(
                      minlen = 2,
                      supp = 50 / length(cjb_trans),
                      target = "frequent itemsets"
                    ))
inspect(itemsets)
irules_induced <- ruleInduction(itemsets, 
                                cjb_trans,
                                confidence = 0.8)
irules_induced
#> set of 5584 rules 

#显然，只要参数是一样的
#得到规则条数也是一样的

#1-项集的频繁程度
itemFrequency(cjb_trans, type = "relative")
itemFrequencyPlot(cjb_trans)
#当然我们更愿意统一成ggplot2的风格
item_freq <- itemFrequency(cjb_trans, type = "relative")
library(tidyverse)
item_freq %>%
  as.data.frame %>%
  rownames_to_column(var = "item") %>%
  mutate(item = factor(item, levels = item)) %>%
  ggplot(aes(x = item, y = item_freq, fill = item_freq)) +
  geom_bar(stat = "identity") +
  theme(axis.text.x  = element_text(angle=60, vjust=1, hjust = 1))
#保留现有的因子水平，也有下述方法
item_freq %>%
  as.data.frame %>%
  rownames_to_column(var = "item") %>%
  mutate(item = forcats::fct_inorder(item)) %>%
  ggplot(aes(x = item, y = item_freq, fill = item_freq)) +
  geom_bar(stat = "identity") +
  theme(axis.text.x  = element_text(angle=60, vjust=1, hjust = 1))



#######################################################
##规则可视化
#######################################################
library(arulesViz)
plot(irules_pruned, method = "graph")#最常用的一种方式
plot(irules_pruned, method = "grouped")
plot(irules_pruned, method = "paracoord")

#交互式的规则可视化
library(tcltk2)
plot(irules_pruned, 
            method="graph", 
            interactive=TRUE)


#######################################################
##规则的导出与保持
#######################################################
#这些规则怎么保存呢？
#当然可以console输出之后复制、或是截图，
#但效果并不好
#稍微好一点的办法是直接将console的结果捕获
out <- capture.output(inspect(irules_pruned))
out
writeLines(out, con = "Rules.txt")
#更好的办法，应该是将规则转换成数据框
#然后另存为csv文件
irules_pruned_in_df <- as(irules_pruned, "data.frame")
View(irules_pruned_in_df)
#考虑到规则中也包含逗号,
#在另存为csv文件时，一般需要设置参数quote=TRUE
write.csv(irules_pruned_in_df, 
          file = "Rules.csv",
          quote = TRUE,
          row.names = FALSE)
#当然，在另存为csv之前，也可以对规则进行必要的处理
irules_pruned_in_df %<>%
  separate(
    rules, 
    sep = "=>",
    into = c("LHS", "RHS")) %>%
  mutate_at(
    vars("LHS", "RHS"),
    funs(gsub("[\\{\\} ]", "", .)))
#转换成data.frame之后
#自然可以随意处置了
#比如可以通过正则表达式任意抽取自己想要的规则
#请小伙伴们自行练习
#当然，arules包中write()函数也可以将规则直接写到本地
write.csv(irules_pruned_in_df, 
      file="Rules2.csv", 
      quote = TRUE,
      row.names=FALSE)  


#以上是R中关于关联规则的基本实现
#感兴趣的同学，可以进一步阅读：
#序列模式arulesSequences等主题
#当然，即便是关联规则，arules当然使用最多
#但也并非是唯一的选择，比如RKEEL等均可尝试

#######################################################
##The End ^-^
#######################################################
