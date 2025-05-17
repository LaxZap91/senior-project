package main

import "core:fmt"
import "core:math/rand"
import "core:math"
import "core:time"
import "core:strconv"
import "core:strings"
import "vendor:raylib"

Vector2 :: [2]f32

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450
PEG_AMOUNT :: 25
GRAVITY :: 500
BALL_INIT_SPEED :: Vector2{300, 200}
BALL_INIT_POS :: Vector2{400, 50}
BALL_SIZE :: 5
PEG_SIZE :: 5

Peg :: struct {
    pos: Vector2,
    activated: bool,
}

Ball :: struct {
    pos: Vector2,
    speed: Vector2,
    isActive: bool,
}

// Randomly generates postions for pegs
generatePegs :: proc() -> (pegs: [PEG_AMOUNT]Peg){
    pos: Vector2
    for i in 0..<len(pegs) {
        for {
            regenerate := false
            pos = Vector2{f32(100 + rand.int31_max(600)), f32(75 + rand.int31_max(350))}

            // Checks if pegs are colliding
            for j in 0..<i {
                if raylib.CheckCollisionCircles(pegs[j].pos, (PEG_SIZE + 5), pos, PEG_SIZE) {
                    regenerate = true
                    break
                }
            }
            if !regenerate {
                break
            }

        }

        pegs[i] = Peg{pos, false}
    }

    return pegs
}

// Draws each peg in the list at their position
drawPegs :: proc(pegs: [PEG_AMOUNT]Peg) {
    for peg in pegs {
        if !peg.activated {
            raylib.DrawCircle(i32(peg.pos.x), i32(peg.pos.y), PEG_SIZE, raylib.BLACK)
        }
    }
}

// Draws a ball at the balls position
drawBall :: proc(ball: Ball) {
    raylib.DrawCircle(i32(ball.pos.x), i32(ball.pos.y), BALL_SIZE, raylib.RED)
}

// Gets the angle between the ball and the mouse position
getBallAngleFromPoint :: proc(point: Vector2, ball: Ball) -> Vector2 {
    x_angle := math.atan((point.x - ball.pos.x) / math.abs(point.y - ball.pos.y))
    y_angle := math.atan((point.y - ball.pos.y) / math.abs(point.y - ball.pos.x))
    return Vector2{x_angle, y_angle}
}

main :: proc() {
    raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Window")
    raylib.SetTargetFPS(30)

    pegs := generatePegs()
    ball := Ball{BALL_INIT_POS, Vector2{0, 0}, false}

    points := 0
    game_running := true


    for !raylib.WindowShouldClose() {
        deltaTime := raylib.GetFrameTime()
        
        // Update Loop
        if game_running {
            // Activates the ball
            if raylib.IsMouseButtonPressed(.LEFT) && !ball.isActive {
                // Gets the angle between the ball and the mouse
                mouse_pos := raylib.GetMousePosition()
                mouse_angle := getBallAngleFromPoint(mouse_pos, ball)


                // Activates ball and sets initial speed
                ball.isActive = true
                ball.speed.x = BALL_INIT_SPEED.x * mouse_angle.x
                ball.speed.y = BALL_INIT_SPEED.y * mouse_angle.y
            }

            // Deals with ball physics
            if ball.isActive {
                // Adjusts the velocity of the ball
                ball.speed.y += GRAVITY * deltaTime
                if ball.speed.x > 0 {
                    ball.speed.x -= 5
                }
                else if ball.speed.x < 0 {
                    ball.speed.x += 5
                }

                // Moves ball
                ball.pos.y += ball.speed.y * deltaTime
                ball.pos.x += ball.speed.x * deltaTime

                // Collision
                for i in 0..<PEG_AMOUNT {
                    
                    if !pegs[i].activated && raylib.CheckCollisionCircles(pegs[i].pos, PEG_SIZE, ball.pos, BALL_SIZE) {
                        ball_angle := getBallAngleFromPoint(pegs[i].pos, ball)

                        // Adjusts the velocity of the ball from the collision (Not good)
                        ball.speed.x = -ball.speed.x * ball_angle.x
                        ball.speed.y = -ball.speed.y + 50

                        pegs[i].activated = true
                        points += 1
                    }
                }

                // Resets ball to start position
                if (ball.pos.y + BALL_SIZE) > SCREEN_HEIGHT {
                    ball.pos = BALL_INIT_POS
                    ball.speed = BALL_INIT_SPEED
                    ball.isActive = false
                }
                // Inverts the velocity of the ball if it hits the edge of the screen
                if (ball.pos.x - BALL_SIZE) < 0 || (ball.pos.x + BALL_SIZE) > SCREEN_WIDTH{
                    ball.speed.x *= -1
                }
            }

            for peg in pegs {
                if !peg.activated {
                    break
                }
                else {
                   game_running = false
                }
            }
        }
        


        // Draw
        raylib.BeginDrawing()
            raylib.ClearBackground(raylib.WHITE)

            if game_running {
                drawPegs(pegs)
                drawBall(ball)
            }
            else {
                points := strings.clone_to_cstring(fmt.tprintf("Points: %d", points))
                raylib.DrawText(points, 300, 225, 50, raylib.BLACK)
            }

        raylib.EndDrawing()
    }

    raylib.CloseWindow()
}