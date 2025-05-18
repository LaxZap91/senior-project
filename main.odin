package main

import "core:fmt"
import "core:math/rand"
import "core:math"
import "core:strings"
import "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450
PEG_AMOUNT :: 30
GRAVITY :: 500
BALL_INIT_SPEED :: raylib.Vector2{300, 200}
BALL_INIT_POS :: raylib.Vector2{400, 50}
BALL_SIZE :: 8
PEG_SIZE :: 8

Peg :: struct {
    pos: raylib.Vector2,
    hit: bool,
}

Ball :: struct {
    pos: raylib.Vector2,
    speed: raylib.Vector2,
    isActive: bool,
}

// Randomly generates postions for pegs
generatePegs :: proc() -> (pegs: [PEG_AMOUNT]Peg){
    pos: raylib.Vector2
    for i in 0..<len(pegs) {
        for {
            regenerate := false
            pos = raylib.Vector2{f32(50 + rand.int31_max(700)), f32(rand.int31_max(400))}

            // Checks if pegs are colliding
            for j in 0..<i {
                if raylib.CheckCollisionCircles(pegs[j].pos, (PEG_SIZE + 5), pos, PEG_SIZE) {
                    regenerate = true
                    break
                }
            }
            if !raylib.CheckCollisionPointCircle(pos, raylib.Vector2{400, 450}, 350) {
                regenerate = true
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
        if !peg.hit {
            raylib.DrawCircle(i32(peg.pos.x), i32(peg.pos.y), PEG_SIZE, raylib.BLACK)
        }
    }
}

// Draws a ball at the balls position
drawBall :: proc(ball: Ball) {
    raylib.DrawCircle(i32(ball.pos.x), i32(ball.pos.y), BALL_SIZE, raylib.RED)
}

// Gets the angle between the ball and the mouse position
getBallAngleFromPoint :: proc(point: raylib.Vector2, ball: Ball) -> raylib.Vector2 {
    x_angle := (math.atan((point.x - ball.pos.x) / abs(point.y - ball.pos.y)) * 2) / math.PI
    y_angle := (math.atan((point.y - ball.pos.y) / abs(point.x - ball.pos.x)) * 2) / math.PI
    return raylib.Vector2{x_angle, y_angle}
}


main :: proc() {
    raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Window")
    raylib.SetTargetFPS(30)

    pegs := generatePegs()
    ball := Ball{BALL_INIT_POS, raylib.Vector2{}, false}

    points := 0
    point_mod := 1
    balls_left := 2
    game_running := true


    for !raylib.WindowShouldClose() {
        deltaTime := raylib.GetFrameTime()
        
        // Update Loop
        if game_running {
            // Activates the ball
            if raylib.IsMouseButtonPressed(.LEFT) && !ball.isActive {
                // Gets the angle between the ball and the mouse
                mouse_angle := getBallAngleFromPoint(raylib.GetMousePosition(), ball)


                // Activates ball and sets initial speed
                ball.isActive = true
                ball.speed = BALL_INIT_SPEED * mouse_angle
            }

            // Deals with ball physics
            if ball.isActive {
                // Adjusts the velocity of the ball
                ball.speed.y += GRAVITY * deltaTime
                ball.speed.x = -raylib.Lerp(ball.speed.x, 0, 2)

                // Moves ball
                ball.pos += ball.speed * deltaTime

                // Collision
                for i in 0..<PEG_AMOUNT {
                    
                    if !pegs[i].hit && raylib.CheckCollisionCircles(pegs[i].pos, PEG_SIZE, ball.pos, BALL_SIZE) {
                        ball_angle := getBallAngleFromPoint(pegs[i].pos, ball)

                        // Adjusts the velocity of the ball from the collision
                        ball.speed.x *= -0.8 * math.sign(ball_angle.x)
                        ball.speed.y *= -0.8 * math.sign(ball_angle.y)

                        pegs[i].hit = true
                        points += point_mod
                        point_mod += 1
                    }
                }

                // Resets ball to start position
                if (ball.pos.y + BALL_SIZE) > SCREEN_HEIGHT {
                    ball.pos = BALL_INIT_POS
                    ball.speed = BALL_INIT_SPEED
                    ball.isActive = false
                    point_mod = 1
                    balls_left -= 1
                }
                // Inverts the velocity of the ball if it hits the edge of the screen
                if (ball.pos.x - BALL_SIZE) < 0 || (ball.pos.x + BALL_SIZE) > SCREEN_WIDTH{
                    ball.speed.x *= -0.9
                }
            }
            
            
            for peg in pegs {
                if peg.hit {
                    game_running = false
                }
                else {
                    game_running = true
                    break
                }
            }
            if balls_left == 0 {
                game_running = false
            }
        }


        // Draw
        raylib.BeginDrawing()
            raylib.ClearBackground(raylib.WHITE)

            points_txt := raylib.TextFormat("Points: %d", points)
            if game_running {
                drawPegs(pegs)
                drawBall(ball)

                balls_left_txt := raylib.TextFormat("Balls Remaining: %d", balls_left)

                raylib.DrawText(points_txt, 5, 5, 20, raylib.BLACK)
                raylib.DrawText(balls_left_txt, 5, 10+20, 20, raylib.BLACK)
            }
            else {
                raylib.DrawText(points_txt, (SCREEN_WIDTH / 2) - (raylib.MeasureText(points_txt, 50) / 2), (SCREEN_HEIGHT / 2) - 25, 50, raylib.BLACK)
            }

        raylib.EndDrawing()
    }

    raylib.CloseWindow()
}