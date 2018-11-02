;;init var
patches-own [energy]      ;Resources in patch
turtles-own [reserves c_rate m_rate maint_cost mutated?]      ;Current resources, Consumption rate, motility rate, basal metabolic rate, and tracker of evolutionary history
globals [cancer_pop invaded?] ;Cancer population counter, and invasion status tracker


to setup
 clear-all
 setup-world
 setup-tissue
 ;setup-cells    Does the same thing as setup tissue, but non-uniform distribution of cells
 reset-ticks

 if file_write?
 [
  file-init       ; Initializes file io
 ]

end


;; Distributes energy to patches
to setup-world
 ask patches
  [
  set energy init_energy     ;Sets init energy of each patch to init_energy
  ]
end

;; Nonuniform initialization of cells
to setup-cells
 create-turtles number_cells
 [
 setxy random world-width random world-height           ;Random Position
 set color yellow                                       ;Unmutated Color
 set c_rate consumption_rate                            ;sets turtles variables to initial slider settings
 set maint_cost base_maint_cost                         ;Initializes maint costs of cells
 set m_rate initial_m_rate                              ;sets movement rate to initial_movement_rate
 set mutated? false
 set invaded? false
 set shape "circle"
 set reserves random repro_threshold                    ;Sets init reserves of each cell from 0-50, staggered reproduction results
 ]
end

;;Uniform initialization of cells
to setup-tissue
 ask patches
  [
  sprout number_cells ; Initializes with number_cells per patch
                      ;(floor renewal_rate / base_maint_cost)  other option is exactly a carrying capacity of cells.
   [
   set color yellow                        ;All cells start as unmutated coloring
   set c_rate consumption_rate             ;sets turtles variables to initial slider settings
   set maint_cost base_maint_cost          ;Initializes maint costs of cells
   set m_rate initial_m_rate               ;sets movement rate to initial_movement_rate
   set mutated? false
   set invaded? false
   set shape "circle"
   set reserves init_cell_reserves         ;random repro_threshold      ;Sets init reserves of each cell to init_cell_reserves, other option random
   ]
  ]
end



to go
  tick
  ask patches [go-patches]
  ask turtles [go-cells]
  go-obs

  count-cancer

  ;;STOP CRITERIA
  ;Hard Stop
  if ticks = stop_time [
    file-close-all
    stop
  ]

  ;Dynamic Stop
  ;Stop if proportion of cancer is larger than stop_prop and invasion has occured.
  if ((cancer_pop)/(count turtles) > stop_prop and invaded?)
  [
    file-close-all
    stop
  ]

end


; Master function for cell action
to go-cells

  ;Move
  if (random-float 1 < m_rate) [move]

  ;Consume resources
  set reserves (reserves - maint_cost)

  ;Reproduce
  if (reserves > repro_threshold) [reproduce]

  ;Die
  if reserves < 0 [die]
  if random-float 1 < background_mortality [die]

end

to move
 ;setxy ((xcor + random 3) - 1) ((ycor + random 3) - 1)    ;makes agents change xcor and ycor to +-1, or 0). Alternative to random motion, guarantees patch centering.

  ;This checks for invasion by comparing patch coordinates
  if (not invaded? and c_rate > consumption_rate)
  [
    let XChange abs ([pxcor] of (patch-ahead 1) - xcor)
    let YChange abs ([pycor] of (patch-ahead 1) - ycor)

    if (XChange > 2 or YChange > 2)
    [
      set invaded? true
    ]
  ]

 fd 1
 if random_move? = true
  [set heading random 360] ;sets heading randomly, enabling random motion

end


to reproduce
 set reserves reserves / 2     ; Halve reserves, to be distributed amongst daughter cells

  hatch 1    ; Create the daughter cell
  [
    ;Randomize facing
    set heading random 360

    ;If mutation occurs
    if random-float 1 < mut_chance
    [
      set mutated? true                  ;Record mutation history
      set color red                      ;Change color

      if c_evo? = true                   ; Mutate consumption rate
      [
        set c_rate c_rate + (random-normal 0 mut_sd) ;mutates c_rate to M=0, SD=mut_rate
      ]

      if m_evo? = true                   ; Mutate mobility rate
      [
        set m_rate m_rate + (random-normal 0 mut_sd) ;mutates c_rate to M=0, SD=mut_rate

        ;if m_rate < 0                   ;Optional, bound m_rate > 0
        ;[set m_rate 0]
      ]
    ]
  ]

end



; Master function for patches
to go-patches
  set energy (energy + renewal_rate)    ; Renew resources

  distribute-energy

end


;Function to proportionally distribute patch resources
to distribute-energy

  let total_demand (sum [c_rate] of turtles-here)                           ;Find total energy needed

  ifelse total_demand < energy                                              ;If we have enough energy, give everyone what they want
  [
    set energy (energy - total_demand)
    ask turtles-here [set reserves (reserves + c_rate)]
  ]
  [

    ask turtles-here [
      set reserves (reserves + (c_rate / total_demand) * energy)            ;Else, distribute energy proportionally
    ]

    set energy 0

  ]

end





; Master function for system
to go-obs
 diffuse energy (diffusion_amount)   ; Diffuse patch resources

 if file_write?
 [
  export-data                         ; Save, analyse, and export data
 ]
end

;Counts cancer
to count-cancer
  set cancer_pop (count turtles with [c_rate > 1 and m_rate > 0])

end



;initializes file io
to file-init

 file-open file_name
 file-write "time"
 file-write "normal population"
 file-write "cancer population"
 file-write "cancer proportion"
 file-write "average motility"
 file-write "average consumption rate"
 file-write "average cancer motility"
 file-write "average cancer consumption rate"
 file-print (word "renewal_rate:" renewal_rate)

end


;Saves, analyses, and exports data
to export-data

 let cancer (count turtles with [color = blue])
 let normal_pop (count turtles with [color = yellow])

 file-write ticks
 file-write normal_pop
 file-write cancer_pop
 file-write (cancer) / (count turtles)
 file-write mean [m_rate] of turtles
 file-write mean [c_rate] of turtles

 ifelse count (turtles with [color = blue]) > 0
 [
  file-write mean [m_rate] of (turtles with [color = blue])
  file-write mean [c_rate] of (turtles with [color = blue])
 ]
 [
   file-write 0
   file-write 0
 ]

 file-print ""


end
@#$#@#$#@
GRAPHICS-WINDOW
770
11
1208
450
-1
-1
8.4314
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
30.0

BUTTON
334
25
397
58
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
1

BUTTON
412
26
475
59
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
1

PLOT
10
127
380
418
Movement Rate Over Time
Time
Movement Rate
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Unmutated" 1.0 0 -1184463 true "" "ifelse count turtles with [not mutated?] > 0\n[\nplot mean [m_rate] of turtles with [not mutated?]\n]\n[\nplot 0\n]"
"Mutated" 1.0 0 -2674135 true "" "ifelse count turtles with [mutated?] > 0\n[\nplot mean [m_rate] of turtles with [mutated?]\n]\n[\nplot 0\n]"
"Cancer" 1.0 0 -13345367 true "" "ifelse count turtles with [c_rate > 1 and m_rate > 0] > 0\n[\nplot mean [m_rate] of turtles with [c_rate > 1 and m_rate > 0]\n]\n[\nplot 0\n]"

MONITOR
39
450
113
495
Unmutated
mean [m_rate] of turtles with [color = yellow]
4
1
11

TEXTBOX
157
429
216
447
Movement
11
0.0
1

TEXTBOX
512
425
662
443
Number of Cells
11
0.0
1

MONITOR
420
448
510
493
Unmutated
count turtles with [color = yellow]
17
1
11

SWITCH
195
85
298
118
c_evo?
c_evo?
0
1
-1000

INPUTBOX
780
601
874
661
number_cells
4.0
1
0
Number

INPUTBOX
777
467
870
527
repro_threshold
50.0
1
0
Number

SWITCH
317
81
420
114
m_evo?
m_evo?
0
1
-1000

SWITCH
434
85
574
118
random_move?
random_move?
0
1
-1000

INPUTBOX
1036
603
1100
663
mut_sd
0.1
1
0
Number

INPUTBOX
878
533
984
593
diffusion_amount
0.01
1
0
Number

PLOT
388
128
762
418
Population
Time
Cell Population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Unmutated" 1.0 0 -1184463 true "" "plot count turtles with [not mutated?]"
"Mutated" 1.0 0 -2674135 true "" "plot count turtles with [mutated?]"
"Cancer" 1.0 0 -13345367 true "" "plot cancer_pop"

INPUTBOX
1113
533
1217
593
stop_time
-1.0
1
0
Number

INPUTBOX
877
467
983
527
consumption_rate
1.0
1
0
Number

INPUTBOX
1111
604
1216
664
base_maint_cost
0.5
1
0
Number

INPUTBOX
780
534
866
594
renewal_rate
8.0
1
0
Number

INPUTBOX
882
603
1009
663
file_name
data5.txt
1
0
String

SWITCH
70
82
182
115
file_write?
file_write?
1
1
-1000

PLOT
11
507
364
756
Consumption Rate Over Time (By Cell Type)
Time
Average Consumption Rate
0.0
10.0
0.0
2.0
true
true
"" ""
PENS
"Unmutated" 1.0 0 -1184463 true "" "ifelse count turtles with [color = yellow] > 0\n[\nplot mean [c_rate] of turtles with [color = yellow]\n]\n[\nplot 0\n]"
"Mutated" 1.0 0 -2674135 true "" "ifelse count turtles with [mutated?] > 0\n[\nplot mean [c_rate] of turtles with [mutated?]\n]\n[\nplot 0\n]"
"Cancer" 1.0 0 -13345367 true "" "ifelse count turtles with [c_rate > 1 and m_rate > 0] > 0\n[\nplot mean [c_rate] of turtles with [c_rate > 1 and m_rate > 0]\n]\n[\nplot 0\n]"

INPUTBOX
997
469
1089
529
mut_chance
1.0
1
0
Number

MONITOR
126
450
200
495
Mutated
mean [m_rate] of turtles with [mutated?]
4
1
11

MONITOR
526
449
585
494
Mutated
count turtles with [mutated?]
4
1
11

PLOT
402
510
738
750
Patch Energy
Energy
Number of Patches
0.0
50.0
0.0
10.0
false
false
"set-histogram-num-bars 100" ""
PENS
"Energy" 1.0 1 -16382462 true "" "histogram [energy] of patches"

INPUTBOX
782
676
876
736
init_energy
4.0
1
0
Number

INPUTBOX
895
672
1050
732
init_cell_reserves
25.0
1
0
Number

MONITOR
647
453
704
498
Cancer
cancer_pop
17
1
11

INPUTBOX
997
535
1104
595
stop_prop
0.5
1
0
Number

PLOT
9
767
361
1023
Standard Deviation of Consumption Rates
Time
SD
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot standard-deviation [c_rate] of turtles"

MONITOR
463
780
669
825
Invasion
invaded?
17
1
11

INPUTBOX
1058
667
1213
727
background_mortality
1.0E-6
1
0
Number

INPUTBOX
1105
470
1213
530
initial_m_rate
0.0
1
0
Number

BUTTON
648
30
751
63
Color Cancer
if (c_rate > 1 and m_rate > 0)[set color blue]
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the relationship between metabolic rate, motility, neoplasticity, and resource availability, in a dynamically evolving cell population. The ambient and uniform renewal rate is used to represent resource availability.

## HOW IT WORKS

We assume a single population of cells, which are homogenous in their initial movement and consumption rates. We begin from a uniform distribution of cells, and a uniform distribution of resources within microenvironments. Furthermore, each cell is initialized with a uniform amount of resources. Unmutated cels are denoted in yellow, mutated cells in red. Cancer cells are not colored, but are plotted, defined as mutated cells with motility and consumption rate higher than unmutated cells.

###MODEL SCHEDULE

In each time step:

For each microenvironment:

1. Renew resource according to rate of renewal.

2. Distribute resources to cells on the microenvironment. If resource supply is insufficient to satisfy the resource demand of the cells, available resources are distributed proportionally, based on the relative consumption rates of the cells.

For each cell:

1. According to movement rate, move forward 1 microenvironment width in a random heading

2. Consume resources from cellular reserves according to the total metabolic rate.

3. If energy is above reproduction threshold, and a random number from 0 to 1 is below the mut_chance, reproduce. Cells split their energy between two daughter cells upon reproduction. Motility rate and consumption rate mutates in 1 daughter cell every time a cell reproduces, and the size of the mutation is a random number drawn from a distribution with a mean 0 and a SD of 0.1. Daughter cells are placed in the same microenvironment as parent.

4. Die if internal reserves are below zero;

Then,

For each microenvironment, diffuse resource according to diffusion rate,


## HOW TO USE IT

###Experimental Parameters:

> renewal_rate - The amount of resources replenished to each microenvironment each time step.


###Fixed Parameters:


> consumption_rate - the metabolic rate for normal cells, or the amount of resources each cell consumes from its microenvironment per time step.

> c_evo? - Toggles evolution of metabolic rate.

> m_evo? - Toggles evolution of motility rate.

> random_move? - Toggles randomization of movement heading.

> initial_m_rate - The initial motility rate, or probability that a given cell will move in a time step.

> mut_chance - The probability that a given cell division will have a mutated daughter cell.

> number_cells - The number of starting cells per microenvironment.

> mut_sd - The standard deviation for mutations.

> base_maint_cost - The basal energy consumption of each cell per turn.

> repro_threshold - The level of resources in a cell required in order to trigger cell division.

> diffusion_amount - The porportion of resources which are diffused to neighboring patches during each time step. 

> warm_up_period - The time at which to begin calculating running averages for data export. (CURRENTLY UNUSED)

> stop_time - The time at which to terminate the simulation, and thus an upper limit for simulation termination, if dynamic termination does not occur first. To inactivate, set to -1.

> stop_prop - The proportion of cancer in the population which is sufficient to terminate the simulation.

> init_cell_reserves - The amount of cellular energy reserves each cell starts with in the simulation.

> init_energy - The initial amount of energy available in each microenvironment.

> background_mortality - The chance of death for any given cell in a given time step.

> file_name - The name of the file that data is exported to.

## EXPERIMENTATION

The effect of resource disparity, on neoplastic dominance and motility, is the key question. We are interested in the coevolution, and speed of coevolution, between motility and consumption rates, and thus, the effect of resource excess on carcinogenesis.

The simulation is terminated when the end-time is reached, or when neoplastic cells become the dominant subpopulation. A cell is designated neoplastic when its motility and consumption are both higher than that of normal cells.

Data is exported to a text file, and is analysed for the effect of renewal rates on fixation speeds.

## EXTENDING THE MODEL

Investigate population heterogeneity, long term evolutionary interactions, and include spatial distinctions. Quantify types and mechanisms of competition, or include more biological details.


## CREDITS AND REFERENCES

Original model developed by Aktipis et al, 2011.
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Resource Test" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>(cancer_pop) / (count turtles) &gt; stop_prop</exitCondition>
    <metric>ticks</metric>
    <metric>count turtles</metric>
    <metric>count turtles with [color = red]</metric>
    <metric>cancer_pop</metric>
    <metric>mean [c_rate] of (turtles with [color = red])</metric>
    <metric>mean [m_rate] of (turtles with [color = red])</metric>
    <metric>mean [c_rate] of (turtles with [c_rate &gt; 1 and m_rate &gt; 0])</metric>
    <metric>mean [m_rate] of (turtles with [c_rate &gt; 1 and m_rate &gt; 0])</metric>
    <enumeratedValueSet variable="init_energy">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random_move?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop_time">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_m_rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop_prop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init_cell_reserves">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_cells">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="background_mortality">
      <value value="1.0E-6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="m_evo?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="renewal_rate">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base_maint_cost">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="file_name">
      <value value="&quot;data5.txt&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="file_write?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut_chance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c_evo?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion_amount">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repro_threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mut_sd">
      <value value="0.1"/>
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
