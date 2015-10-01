turtles-own [ ;; this is a very long list of attributes that turtles possess
  
 ;; base SES attributes needed for original opinion
 age
 gender
 education 
 
;; error term to add some "spice" to the OLS equation
 random-jitter
 
 ;; Value hierarchy. Basic list of values have already been constructed as a global preference
 value-priority ;; list of weights assigned to each value in the hierarchy (which is defined globally)
 reconsider? ;; will agent reconsider?
 changed? ;; has agent's opinion changed since the last iteration?
 
 ;; opinion-level as calculated by an OLS equation, then translated to TRUE or FALSE in approve?
 opinion-level ;; decimal level approximation of preference
 approve? ;; boolean approval

 ;;social interactions statistics
 neighbors-num ;; how many neighbors? defined according to needs of program. v2 defines it as number of neighbors with similar first-order preference
 total-agree ;; how many approve of policy? used for calculating agent's own preference
 
 ;; for bookkeeping only
 temp-priority
 temp-list
 temp-approve?
 
 ;; these are for determining which value is primary, which will be converted into booleans below
 ;; first-order value, its numerical weight, also position in the list
 max-value
 max-value-weight
 max-position

 ;; second-order value
 second-value
 second-value-weight
 second-position
 
 ;; third-order values, for future extension of program
 third-value
 third-value-weight
 third-position
 
  ;; booleans for determining which value takes precedence
 group-dom?
 pol-eq?
 conserve?
]


;; global attributes to keep track of
globals
[
  value-list 
  total-approval ;; total # of approving turtles
  pct-approval ;; percentage, just because it's convenient

  ;;Whether an information shock has been applied, either TRUE or FALSE
  info-shock?
  
  num-changed

  reconsider-change
  reconsider-not-change
  
  clean-up?
]

;; SETUP takes a few routines
to setup
  clear-all
  
    ;; if you generate more turtles than patches, spit out error message.
  if num-agents > count patches
    [ user-message (word "This pond only has room for " count patches " turtles.") 
      ;; this should never happen as number is limited to max number of patches (default is 1089) but it pays to be safe
      stop ]
    
     ;;set shape so that turtles are people, too
  set-default-shape turtles "person"
  
  ;; Set up global list of values as defined by PS and psych literature. At first this is random.
  set value-list ["political equality" "conservatism" "group dominance"]
  set clean-up? FALSE
  
  ;; Great, now create turtles with specified attributes on random patches.
  ask n-of num-agents patches
    [ sprout 1
      [ make-attributes ] ]
   
  ;; the info shock is initially not applied. We let everyone come to a natural opinion of sorts
  clean-up-globals
        
  ;; just to clear ticks  
  reset-ticks
end


;;Initiats SES attributes for each turtle. Set SES Attributs according to ANES data, range of data 18 to 93
to make-attributes
  
  ;;Set SES Attributs according to ANES data, range of data 18 to 93
  set age 0
  while [age < 18 OR age > 93] [set age random-normal 47.39 18.88] ;; making the person have an age
  
  ;; gender and education are randomly generated
  set gender random 2 ;; where 0 is male and 1 is female
  set education 1 + random 5  ;;  five levels of education, generated randomly. We add 1 because 0 is not a value in the ANES
  
  ;; sum up according to OLS equation with a little bit of randomness
  set random-jitter -1
  
  ;;we want to set a random-jitter parameter that is not catastrophically large, so we iterate until something plausible comes up
  while [random-jitter < -0.2 OR random-jitter > 0.18] [set random-jitter random-normal 0 0.2]
  
  ;; abortion for health regression regression equation
  set opinion-level 0.307 + 0.075 * education - 0.001 * age + 0.031 * gender + random-jitter
  
  ;;comment out the line above and uncomment out the following line if you want to look at support for private investment of social security funds!
  ;; set opinion-level 0.772 + 0.008 * education - 0.007 * age + 0.102 * gender + random-jitter

  ;; determine approval based on calculated opinion-level and color accordingly. BLUE is approve, WHITE is not approve.
  ifelse opinion-level >= 0.5 
   [ set approve? TRUE 
     set color blue ] 
   [ set approve? FALSE 
     set color white ]
    
  ;;now we need to determine the weights of each value drawn randomly from a uniform distribution 
  
  set value-priority [] ;; start empty list, otherwise program will throw an error message
  foreach value-list [ set value-priority lput random 101  value-priority] ;; generate random weighting for each value
  find-priority ;; determine what is first-, second- and third-order
  set-bool max-value
  
  set changed? FALSE ;; initially, you have no opinion to change
  set reconsider? FALSE ;; tracks if the person reconsidered his decision
  set neighbors-num 0 ;; how many neighbors does he have?
  set total-agree 0 ;; how many people agree with this opinion? Before there's an issue, there is no agreement.

end

to set-bool [temp-max-value] ;; sets value priority. The three are booleans 
  ifelse temp-max-value = "political equality" [ set pol-eq? TRUE ] [ set pol-eq? FALSE ]
  ifelse temp-max-value = "conservatism" [ set conserve? TRUE ] [ set conserve? FALSE ]
  ifelse temp-max-value = "group dominance" [ set group-dom? TRUE ] [ set group-dom? FALSE]
end

;;determine priority of values in the turtle
to find-priority
  
  ;;set up a temporary list
  set temp-list value-list
  set temp-priority value-priority
    
  ;;sort through initial list, assign first position to most valued priority, then remove it from the initial list
  set max-value-weight max temp-priority
  set max-position position max-value-weight temp-priority
  set max-value item max-position temp-list

  set temp-priority remove-item max-position temp-priority 
  set temp-list remove-item max-position temp-list
  
   ;; then sort through reduced initial list and assign next valued priority, etc
  set second-value-weight max temp-priority
  set second-position position second-value-weight temp-priority
  set second-value item second-position temp-list  
  
  set temp-priority remove-item second-position temp-priority 
  set temp-list remove-item second-position temp-list
  
  set third-value-weight max temp-priority
  set third-position position third-value-weight temp-priority
  set third-value item third-position temp-list  
  
  set temp-priority remove-item third-position temp-priority 
  set temp-list remove-item third-position temp-list
 
end

;; Clean up if you want to set up for a new random simulation. In retrospect, probably not necessary if you use BehaviorSpace to do repeated simulations

to clean-up-globals
  set info-shock? FALSE
  set num-changed 0
  set reconsider-change 0
  set reconsider-not-change 0
end


;; Clean up if you want to set up for a new random simulation. In retrospect, probably not necessary if you use BehaviorSpace to do repeated simulations
to clean-up-turtles ; by observer
  ask turtles [
    set-bool max-value
    set changed? FALSE
    set reconsider? FALSE
    set neighbors-num 0 
    set total-agree 0] 
end

;; GO IS HERE
to go
  ;; Only update here if the turtles here are told to reconsider their lives
  ;; otherwise their opinions should be stable
    if clean-up? [  clean-up-turtles
    clean-up-globals ]
    
    ;;if you have applied an information shock, see how many turtles have reconsidered?
  if info-shock? [ update-turtles ]
  update-globals

  tick
end

;;calculate global statistics for stable and reconsidered opinions
to update-globals
  set total-approval count turtles with [ approve? ]
  set pct-approval total-approval / num-agents * 100
  set num-changed count turtles with [ changed? ]
end


;;calculate neighbor opinions, taking into account people with similar value priorities, or at least maximum priorities
;;this version determines just how many neighbors there are that share his first order value preferences
to similar-neighbors [ temp-max-value2 ]
  if temp-max-value2 = "political equality" [
    set neighbors-num count (turtles-on neighbors) with [ pol-eq? ] 
    set total-agree count (turtles-on neighbors) with [ pol-eq? AND approve? ]
  ]
       
  if temp-max-value2 = "conservatism" [   
    set neighbors-num count (turtles-on neighbors) with [ conserve? ] 
    set total-agree count (turtles-on neighbors) with [ conserve? AND approve? ]
  ]
       
  if temp-max-value2 = "group dominance" [      
    set neighbors-num count (turtles-on neighbors) with [ group-dom? ] 
    set total-agree count (turtles-on neighbors) with [ group-dom? AND approve? ]
  ]
end

to update-turtles ;by observer
  ;; first figure out max value, then store what the max value actually is
  ask turtles [  
    if ( max-value-weight - second-value-weight ) < threshold-tolerance ;; totally arbitrary value, we need firmer theoretical justification for this threshold value
    [ 
      set reconsider? TRUE ;; in case I want to count how many people "reconsider" later
      
      similar-neighbors max-value ;; calculate how many neighbors share his first order value preferences
      
      ;; if no first order sharers, check second order value preferences
      if neighbors-num = 0 
      [ set-bool second-value
        similar-neighbors max-value]
      
      ;; then if neighbors > 0, set your opinion according to majority opinion of people who share your value preferences
      if neighbors-num != 0
      [ set opinion-level total-agree / neighbors-num 
      
        ifelse opinion-level >= 0.5 
        [ set temp-approve? TRUE]
        [ set temp-approve? FALSE]
       
        if temp-approve? != approve?
        [ ifelse temp-approve?
          [ set color blue ] 
          [ set color white ]
           set approve? temp-approve?
           set changed? TRUE
        ]
      ]
     
      
    ] 
    
        ;;this is turned on to keep track of how many people have reconsidered and have changed or not changed their minds. You can turn it off for less confusing visuals.
     if reconsider? and changed? [ set color green ]
      if reconsider? and not changed? [ set color red ]
    ]
  
  ;;set reconsider-approve count turtles with [ approve? AND reconsider? and changed?]
  ;;set reconsider-disapprove count turtles with [ reconsider? AND not approve? and changed? ]
  set reconsider-change count turtles with [ reconsider? and changed? ]
  set reconsider-not-change count turtles with [ reconsider? and not changed? ]
  set clean-up? TRUE
  
 end
@#$#@#$#@
GRAPHICS-WINDOW
247
10
686
470
16
16
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
10
10
83
43
Setup
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
10
54
84
87
Go!
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
11
140
183
173
num-agents
num-agents
550
1089
1089
25
1
NIL
HORIZONTAL

BUTTON
9
94
153
127
Information Shock
set info-shock? TRUE
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
10
235
210
385
Public Opinion
Time
% Approval
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"histo" 1.0 1 -16777216 true "" "plot pct-approval"

SLIDER
11
182
189
215
threshold-tolerance
threshold-tolerance
0
50
50
5
1
NIL
HORIZONTAL

MONITOR
700
10
832
55
% approval of policy
pct-approval
2
1
11

MONITOR
700
65
967
110
# Reconsidered and changed preference
reconsider-change
2
1
11

MONITOR
700
120
997
165
# Reconsidered and did not change preference
reconsider-not-change
2
1
11

@#$#@#$#@
## WHAT IS IT?

This is the NetLogo code for "Estimating the Effects of Attitude Structure in Shaping Public Opinion: the significance of the political value structures underlying data simulations of information effects"

Authors: W. Zhang, L. Caughell and A. B. Cronkhite

This version shows how an individual may poll his neighbors to determine whether to support abortion when the health, not the life, of the mother appears in danger.

## HOW IT WORKS

Each turtle is initialized with a randomly assigned age, gender and education level. Then, for a particular issue, we feed these parameters into an OLS regression equation. This equation is derived from an analysis of the 2008 American National Election Survey, in which we examine the relationship between that issue (the paper examines support for abbortion and support for investing social security funds into personal retirement funds) and socioeconomic variables listed above.

These initial opinions are stable until the user manually administers an information shock. In real life, it could be a countervailing opinion or an exposé, then turtles determine whether they should reconsider their opinion. In this version, turtles who think that they should reconsider polls their 8 neighbors, determines which ones share his value preferences. and adjusts their opinions to match the restricted majority opinion. 

## HOW TO USE IT

Press "setup" to set up the initial 33x33 board of turtles. Press "go" to record their initial opinions. Press "information shock" to force turtles to reconsider, and pressing "go" again will show the new distribution of opinions.

This was a fairly simplistic model and is clunky. We made it as part of exploring the application of ABM to political behavior, and was used primarily to generate visuals to show that proximity to different neighborhood compositions will drastically change the opinion that a turtle may come.

## THINGS TO NOTICE

The graphs are fairly simplistic, but the graphics are very helpful to understanding how proximity polling may change the composition of opinions in the aggregate.

Blue represents people who agree with a policy. White represents people who do not agree. Green represents people who have reconsidered and have changed their minds and red represents people who reconsidered but then did not change their minds.

## THINGS TO TRY

The obvious: you can change the number of agents as well as the threshold-tolerance (the relative weight he gives to his first- and second- order value preferences), which determines when a turtle will decide to reconsider his policy attitude.

The less obvious (to change in the code): each version also contains code for polling only those neighbors who share the turtle's first-order value preference. Additional code exists for coloring in those people who have reconsidered and have changed their minds (green) as well as those people who reconsidered but then did not change their minds (red). Currently this is turned on and can be confusing to view, but you can turn it off by commenting out two lines of code near the bottom.

Our paper also looked at the support for investing social security funds into personal retirement accounts. The code for the support calculation is included but currently commented out. 

## EXTENDING THE MODEL

Lots of improvements, not just extensions, can be done, including doing away with the annoying procedure (i.e. fewer button clicks) in order to streamline the simulation process. 

We are revising this project to be more fully featured, so stay tuned!

## NETLOGO FEATURES

This is a basic toy model. No special features were used!

## RELATED MODELS

There are models that serve a similar purpose in the Models Library, but nothing that uses empirically based calculations. I will note here that these calculations may have been too complicated for what is really a very simple model.

## CREDITS AND REFERENCES

The full GitHub repository for this project, including paper and code, can be found at https://www.github.com/ZhangWS/mpsa2012/
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
1
@#$#@#$#@
