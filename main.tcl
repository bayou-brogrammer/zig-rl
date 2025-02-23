#!/usr/bin/tclsh
load zig-out/lib/librrl.so
package require rrl
namespace import rrl::*


# Currently to get the player X position.
#Pos create pos
#pos bytes [Comp(Pos) with [Entities with [Level with [Game with [gui ptr game] ptr level] ptr entities] ptr pos] call get 0]
#pos get x

proc pos { x y } {
    return [Pos call init $x $y]
}

set playerId 0


#Display create disp
#set bytes [Display call init 0 400 400 $zigtcl::pageAllocator]
#disp setBytes $bytes
#
#Panel create panel
#panel setBytes [Panel call init [Dims call init 20 20] [Dims call init 20 20]]
#
#TexturePanel create texture_panel
#texture_panel setBytes [disp call texturePanel [panel bytes] $zigtcl::pageAllocator ]
#
#DrawCmd create drawcmd
#
#proc run { } {
#    drawcmd setBytes [DrawCmd call rect [Pos call init 10 10] 2 2 0.0 1 [Color call init 100 100 100 255]]
#    texture_panel call addDrawCmd [drawcmd bytes]
#
#    disp call clear [texture_panel ptr] [Color call init 20 20 20 255]]
#    disp call draw [texture_panel ptr]
#    disp call present [texture_panel ptr]
#    after 100 run
#}
#run
#vwait running

Gui create gui
set bytes [Gui call init 0 $zigtcl::pageAllocator]
gui setBytes $bytes
gui call resolveMessages

InputEvent create event
proc keyDown { chr } {
    event variant char $chr [KeyDir value down]
    gui call inputEvent [event bytes] 0
}

proc keyUp { chr } {
    event variant char $chr [KeyDir value up]
    gui call inputEvent [event bytes] 0
}

proc key { chr } {
    scan $chr %c value
    keyDown $value
    keyUp $value
}

proc space { } {
    keyUp 32
    keyDown 32
}

proc esc { } {
    keyUp 27
    keyDown 27
}

set startupTicks [clock milliseconds]
proc ticks { } {
    global startupTicks
    return [expr [clock milliseconds] - $startupTicks]
}

# Translates
#pos bytes [Comp(Pos) with [Entities with [Level with [Game with [gui ptr game] ptr level] ptr entities] ptr pos] call get 0]
#pos get x
# into 
#pos bytes [Comp(Pos) with [ptr [gui ptr] Gui game Game level Level entities Entities pos] call get 0]
proc ptr { ptr args } { 
    foreach { type field } $args {
        set ptr [$type with $ptr ptr $field]
    }
    return $ptr
}

# Get a component from a particular entity by name.
proc getValue { typ name id } {
    return [Comp($typ) with [ptr [gui ptr] Gui game Game level Level entities Entities $name] call get $id]
}

proc setValue { typ name id value } {
    return [Comp($typ) with [ptr [gui ptr] Gui game Game level Level entities Entities $name] call set $id $value]
}


proc mkKey { name value } { proc $name { } "key $value" }
mkKey up 8
mkKey down 2
mkKey right 6
mkKey left 4
mkKey upLeft 7
mkKey upRight 9
mkKey downLeft 1
mkKey downRight 3

proc run { dir } {
    event variant shift [KeyDir value down]
    gui call inputEvent [event bytes] 0
    $dir
    event variant shift [KeyDir value up]
    gui call inputEvent [event bytes] 0
}

proc sneak { dir } {
    event variant ctrl [KeyDir value down]
    gui call inputEvent [event bytes] 0
    $dir
    event variant ctrl [KeyDir value up]
    gui call inputEvent [event bytes] 0
}

proc renderPeriodically { } {
    set result [gui call step [ticks]]
    if { $result == 1 } {
        after 100 renderPeriodically
    } else {
        gui call deinit
        global running
        set running 0
    }
}

renderPeriodically

#set guiPtr [gui ptr]
#set logPtr [ptr $guiPtr Gui game Game log]
#MsgLog with $logPtr call log yell 0
vwait running
