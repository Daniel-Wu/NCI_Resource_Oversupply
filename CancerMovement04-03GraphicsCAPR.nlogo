patches-own [energy]
turtles-own [reserves c_rate m_rate]
globals [
        mean_norm_m_rate total_norm_m number_norm_m running_ave_norm_m num_norm 
        mean_neo_m_rate total_neo_m number_neo_m running_ave_neo_m num_neo]


to setup
 ca
 setup-world
 setup-tissue
 ;setup-cells
 setup-plot
end

to setup-world
 ask patches 
  [
  set energy initial_energy
  color-patches
  ]
end

to setup-cells
 create-turtles number_cells
 [
 setxy random world-width random world-height
 set color yellow
 set c_rate consumption_rate ;sets turtles variables to initial slider settings
 set m_rate random-normal initial_m_rate mr_sd  ;sets movement rate to M=movement_rate, SD=mr_sd *movement rate must be > 0*
 set shape "circle"
 set reserves random repro_threshold
 ]
end

to setup-tissue
 ask patches 
  [
  sprout 1
   [
   set color yellow
   set c_rate consumption_rate ;sets turtles variables to initial slider settings
   set m_rate random-normal initial_m_rate mr_sd  ;sets movement rate to M=movement_rate, SD=mr_sd *movement rate must be > 0*
   set shape "circle"
   set reserves random repro_threshold
   ]
  ] 
end

to go
  ask turtles [go-cells]
  ask patches [go-patches]
  go-obs
  tick
  if ticks > warm_up_period [report_ave]
  if ticks = 100000 [stop]
end

to go-cells
 if random-float 1 < m_rate [move]
 eat
 if reserves > repro_threshold [reproduce]
 if energy < death_threshold [die]  ;if you're on a patch with no energy, die 
 if color = yellow [set color scale-color yellow energy 0 15]
 ;if color = blue [set color scale-color blue energy 0 15]
end

to move
 ;setxy ((xcor + random 3) - 1) ((ycor + random 3) - 1)    ;makes agents change xcor and ycor to +-1, or 0)
 fd 1
 if random_move? = true
  [set heading random 360] ;sets motion random
end

to eat
 if energy > 0
  [
  set energy energy - c_rate
  set reserves reserves + c_rate
  ]
end

to reproduce  ;needs to be updated with new rules
 set reserves reserves / 2
  hatch 1
  [
  set heading random 360
  ;fd 1  so cells stay on parent patch
  if c_evo? = true 
   [
   set c_rate c_rate + (random-normal 0 mut_sd) ;mutates c_rate to M=0, SD=mut_rate
   ]
  if m_evo? = true 
   [
   set m_rate m_rate + (random-normal 0 mut_sd) ;mutates c_rate to M=0, SD=mut_rate
   ]
  if random-float 1 < iv_mut_rate 
   [mutate-iv]
  ]
end
 

to go-patches 
 grow
 color-patches
end


to grow
 set energy energy + renewal_rate
end

to color-patches
 set pcolor scale-color red energy 0 150
end

to go-obs
 diffuse energy (diffusion_amount)
 update-plot
 calculate-values
end

to mutate-iv
 set c_rate cancer_c_rate
 set color blue
end

to mutate-c_rate
 ask one-of turtles 
  [
   ifelse c_rate = consumption_rate
    [
    set c_rate cancer_c_rate
    set color blue
    ]
    [
    set c_rate consumption_rate
    set color yellow
    ]
   ]
end
 
to setup-plot
  set-current-plot "Movement Rate Over Time"
end

to update-plot
  set-current-plot-pen "Normal"
  ifelse count turtles with [color = yellow ] > 0
   [plot mean [m_rate] of turtles with [color = yellow]  ]    
   [plot 0]
  set-current-plot-pen "Cancer"
  ifelse count turtles with [color = blue ] > 0
   [plot mean [m_rate] of turtles with [color = blue]   ]   
   [plot 0]
end

to calculate-values
 ifelse count turtles with [color = yellow] > 0
  [
  set mean_norm_m_rate (mean [m_rate] of turtles with [color = yellow])
  ]
  [set mean_norm_m_rate " "]
  
 ifelse count turtles with [color = blue] > 0
  [
  set mean_neo_m_rate (mean [m_rate] of turtles with [color = blue])
  ]
  [set mean_neo_m_rate " "]
  
 set num_norm (count turtles with [color = yellow])
 set num_neo (count turtles with [color = blue])
 

end

to report_ave
 if count turtles with [color = yellow] > 0
  [
  set total_norm_m (total_norm_m + mean_norm_m_rate)    ;for running average- total means
  set number_norm_m (number_norm_m + 1)                 ;for running average- number items
  set running_ave_norm_m (total_norm_m / number_norm_m )
  ;print running_ave_norm_m
  ]
  
 if count turtles with [color = blue] > 0
  [
  set total_neo_m (total_neo_m + mean_neo_m_rate)    ;for running average- total means
  set number_neo_m (number_neo_m + 1)                 ;for running average- number items
  set running_ave_neo_m (total_neo_m / number_neo_m )
  ;print running_ave_neo_m
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
387
10
805
449
25
25
8.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks

BUTTON
683
588
793
621
setup-tissue
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
140
10
203
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
-5
532
167
565
consumption_rate
consumption_rate
0
.1
0.01
.001
1
NIL
HORIZONTAL

SLIDER
178
533
447
566
initial_m_rate
initial_m_rate
0
.01
0.0010
.001
1
NIL
HORIZONTAL

SWITCH
31
579
134
612
c_evo?
c_evo?
1
1
-1000

SWITCH
213
578
316
611
m_evo?
m_evo?
0
1
-1000

SLIDER
178
491
350
524
renewal_rate
renewal_rate
0
1
0.01
.01
1
NIL
HORIZONTAL

MONITOR
207
394
263
439
normal
count turtles with [color = yellow ]
17
1
11

MONITOR
10
394
70
439
normal
mean [m_rate] of turtles with [color = yellow]
5
1
11

MONITOR
79
393
155
438
cancer
mean [m_rate] of turtles with [color = blue]
5
1
11

SWITCH
568
650
719
683
random_move?
random_move?
0
1
-1000

BUTTON
10
65
180
98
mutate c_rate of a cell
mutate-c_rate
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
277
394
334
439
cancer
count turtles with [color = blue ]
17
1
11

SLIDER
191
64
363
97
cancer_c_rate
cancer_c_rate
0
.1
0.02
.001
1
NIL
HORIZONTAL

BUTTON
14
11
135
44
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

INPUTBOX
38
649
120
709
number_cells
500
1
0
Number

INPUTBOX
171
648
272
708
death_threshold
1
1
0
Number

INPUTBOX
290
648
445
708
repro_threshold
50
1
0
Number

INPUTBOX
35
728
114
788
mut_sd
0.01
1
0
Number

INPUTBOX
457
649
560
709
diffusion_amount
0.0010
1
0
Number

INPUTBOX
137
727
187
787
mr_sd
0
1
0
Number

INPUTBOX
257
735
412
795
initial_energy
5
1
0
Number

PLOT
17
116
371
356
Movement Rate Over Time
Time
Movement Rate
0.0
10.0
0.0
0.1
true
false
PENS
"Normal" 1.0 0 -955883 true
"Cancer" 1.0 0 -13345367 true

TEXTBOX
39
373
189
391
Movement Rates
11
0.0
1

TEXTBOX
240
375
390
393
Number Cells
11
0.0
1

SLIDER
2
492
174
525
iv_mut_rate
iv_mut_rate
0
1
0.01
.01
1
NIL
HORIZONTAL

TEXTBOX
679
852
1015
964
Setup running average so that netlogo does data handling\nChange mut rate to .001 and test\nClassify patched by majority cell type for invasion
11
0.0
1

INPUTBOX
861
159
1016
219
warm_up_period
1000000
1
0
Number

@#$#@#$#@
WHAT IS IT?
-----------
This section could give a general understanding of what the model is trying to show or explain.


HOW IT WORKS
------------
This section could explain what rules the agents use to create the overall behavior of the model.


HOW TO USE IT
-------------
This section could explain how to use the model, including a description of each of the items in the interface tab.


THINGS TO NOTICE
----------------
This section could give some ideas of things for the user to notice while running the model.


THINGS TO TRY
-------------
This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.


EXTENDING THE MODEL
-------------------
This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.


NETLOGO FEATURES
----------------
This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.


RELATED MODELS
--------------
This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.


CREDITS AND REFERENCES
----------------------
This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="ParametricTest" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000000"/>
    <metric>running_ave_norm_m</metric>
    <enumeratedValueSet variable="cancer_c_rate">
      <value value="0.015"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repro_threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="iv_mut_rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_rate">
      <value value="0.0050"/>
      <value value="0.01"/>
      <value value="0.015"/>
      <value value="0.02"/>
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="renewal_rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_m_rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c_evo?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death_threshold">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_amount">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="m_evo?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_cells">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random_move?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut_sd">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mr_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_energy">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CompetitionTest" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>mean_norm_m_rate</metric>
    <metric>num_norm</metric>
    <metric>mean_neo_m_rate</metric>
    <metric>num_neo</metric>
    <enumeratedValueSet variable="initial_energy">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_amount">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="iv_mut_rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c_evo?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mr_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_m_rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repro_threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random_move?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut_sd">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="m_evo?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cancer_c_rate">
      <value value="0.01"/>
      <value value="0.015"/>
      <value value="0.02"/>
      <value value="0.025"/>
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death_threshold">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="renewal_rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_cells">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
