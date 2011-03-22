package Games::SavingSue::Level;
use strict;
use warnings;
use SDL;
use SDL::Events;
use SDL::Event;
use SDLx::Audio;
use SDL::Rect;
use SDLx::Surface;
use SDLx::Sprite::Animated;
use SDLx::Text;
use Sub::Frequency;

sub startup {
    my ($self, $app) = @_;

    my $road = SDLx::Surface->load('data/road.png');

    my $winning_sounds = SDLx::Audio->new->load(
         1 => 'data/candy.wav',
         2 => 'data/sweet.wav',
         3 => 'data/uhu.wav',
         4 => 'data/yay.wav',
    );
    
    my $losing_sounds = SDLx::Audio->new->load(
         1 => 'data/hurt.wav',
         2 => 'data/man.wav',
         3 => 'data/yikes.wav',
         4 => 'data/ouch.wav',
    );

    my $sue = SDLx::Sprite::Animated->new(
        ticks_per_frame => 7,
        type => 'reverse',
        image => 'data/susan.png',
        clip => SDL::Rect->new( 0,0,72,85 ),
        x => $app->w / 2 - (72 / 2),
        y => $app->h - 85,
    );
    $sue->start;

    my $candy = SDLx::Sprite->new(
        image => 'data/candy.png',
        y     => 15,
    );
    $candy->x( int rand ($app->w - $candy->w) );

    my $score = {
        text  => SDLx::Text->new,
        value => $app->stash->{score} || 0,
    };
    my $lives = {
        image => SDLx::Sprite->new( image => 'data/susan_head.png', y => 30 ),
        text  => SDLx::Text->new( x => 40, y => 30 ),
        value => $app->stash->{lives} || 3,
    };

    my @cars = (
        spawn('car1'),
        spawn('car2'),
        spawn('car3'),
        spawn('car4'),
    );

    my $is_dead = 0;
    $app->add_show_handler( sub {
        $road->blit($app);
        $candy->draw($app);
        $score->{text}->write_to( $app, 'Score: ' . $score->{value} );

        $lives->{image}->draw($app);
        $lives->{text}->write_to( $app, 'x ' . $lives->{value} );
        
        foreach my $car (@cars) {
            $car->{sprite}->draw($app);
        }

        if ($is_dead) {
            my $dead = SDLx::Surface->load('data/susan_dead.png');
            $dead->blit($app, undef, $sue->rect);
            $app->update;

            my $chosen = 1 + int( rand 4 );
            $losing_sounds->play( $chosen );
            while ( $losing_sounds->playing( $chosen ) ) {
                sleep 1;
            }

            $app->stash->{score} = $score->{value};
            $app->stash->{lives} = $lives->{value} - 1;
            if ($app->stash->{lives} > 0) {
                $app->stash->{next_state} = 'Level';
            }
            else {
                $app->stash->{next_state} = 'Menu';
            }
            $app->stop;
        }
        else {
            $sue->draw($app);
            $app->update;
        }
    });

    $app->add_event_handler( sub {
        my ($event, $app) = @_;
        if ($event->type == SDL_KEYDOWN) {
            my $key = $event->key_sym;
            if ($key == SDLK_RIGHT) {
                my $new_x = $sue->x + $sue->clip->w;
                $sue->x( $new_x ) if $new_x + $sue->clip->w <= $app->w;
            }
            elsif ($key == SDLK_DOWN) {
                my $new_y = $sue->y + $sue->clip->h;
                $sue->y( $new_y ) if $new_y + $sue->clip->h <= $app->h;
            }
            elsif ($key == SDLK_LEFT) {
                my $new_x = $sue->x - $sue->clip->w;
                $sue->x( $new_x ) if $new_x >= 0;
            }
            elsif ($key == SDLK_UP) {
                my $new_y = $sue->y - $sue->clip->h;
                $sue->y( $new_y ) if $new_y >= 0;
            }
        }
    });

    $app->add_move_handler( sub {
        my ($delta, $app) = @_;

        if ($sue->rect->colliderect($candy->rect)) {
            $winning_sounds->play( 1 + int( rand 4 ) );
            $candy->y( $candy->y == 15 ? $app->h - 50 : 15 );
            $candy->x( int rand ($app->w - $candy->w) );

            $score->{value} += 10;
            if ($score->{value} % 200 == 0) {
                $lives->{value}++;
            }
        }
    });

    $app->add_move_handler( sub {
        my ($delta, $app) = @_;

        if (defined $sue->rect->collidelist( [ map { $_->{sprite}->rect } @cars ] ) ) {
            $is_dead = 1;
            # player died, only keep the show handlers
            $app->remove_all_event_handlers;
            $app->remove_all_move_handlers;
        }
    });

    $app->add_move_handler( sub {
        my ($delta, $app) = @_;
        my @new_cars = ();

        foreach my $i (0 .. $#cars) {
            my $car = $cars[$i];
            $car->{float_x} += ($car->{speed} * $delta);
            $car->{sprite}->x( $car->{float_x} ); # x() truncates the value

            # if there's enough room, we can add a new car
            if ($car->{status} eq 'entering') {
                if (
                    ( $car->{speed} < 0
                      and $car->{sprite}->x + $car->{sprite}->w + ($sue->w * 2) < $app->w
                    )
                 or (
                      $car->{speed} > 0
                      and $car->{sprite}->x - ($sue->w * 2) > 0
                    )
                ) {
                    with_probability $car->{frequency} => sub {
                        push @new_cars, spawn($car->{name});
                        $car->{status} = 'in';
                    };
                }
            }

            # we only keep cars that are still on screen
            if ($car->{sprite}->x <= $app->w
                and $car->{sprite}->x + $car->{sprite}->w >= 0
            ) {
                push @new_cars, $car;
            }
        }

        # failsafe in case no car is spawn in each lane
        my %seen = ( car1 => 0, car2 => 0, car3 => 0, car4 => 0 );
        foreach my $car (@new_cars) {
            $seen{ $car->{name} }++;
        }
        foreach my $type (keys %seen) {
            push @new_cars, spawn($type)
                if $seen{$type} == 0;
        }

        @cars = @new_cars;
    });
}

sub spawn {
    my $type = shift;

    my %cars = (
        car1 => {
          name      => 'car1',
          sprite    => SDLx::Sprite->new( image => 'data/car1.png', x => 800, y => 90 ),
          speed     => -23,
          float_x   => 800,
          status    => 'entering',
          frequency => 0.01,
        },
        car2 => {
          name      => 'car2',
          sprite    => SDLx::Sprite->new( image => 'data/car4.png', x => -210, y => 177 ),
          speed     => 40,
          float_x   => -210,
          status    => 'entering',
          frequency => 0.005
        },
        car3 => {
          name       => 'car3',
          sprite     => SDLx::Sprite->new( image => 'data/car3.png', x => 800, y => 264 ),
          speed      => -15,
          float_x    => 800,
          status     => 'entering',
          frequency => 0.01,
        },
        car4 => {
          name       => 'car4',
          sprite     => SDLx::Sprite->new( image => 'data/car2.png', x => -183, y => 346 ),
          speed      => 10,
          float_x    => -183,
          status     => 'entering',
          frequency  => 0.008,
        },
    );
    
    return $cars{$type};
}


'all your game are belong to us'
