from datetime import datetime as dt
from rich import print
import time, sys


animation = [
"[        ]",
"[=       ]",
"[===     ]",
"[====    ]",
"[=====   ]",
"[======  ]",
"[======= ]",
"[========]",
"[ =======]",
"[  ======]",
"[   =====]",
"[    ====]",
"[     ===]",
"[      ==]",
"[       =]",
"[        ]",
"[        ]"
]
def until_complete(message:str, period:int):
    flag_ = 0
    i = 0
    death = int(dt.now().timestamp()) + period

    while flag_ == 0:
        print(animation[i % len(animation)], message, sep=' ', end='\r')
        time.sleep(.1)
        i += 1

        if int(dt.now().timestamp()) == death: flag_ = 1 
