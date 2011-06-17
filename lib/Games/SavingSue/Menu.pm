package Games::SavingSue::Menu;
use Avenger;
use SDLx::Audio;
use SDLx::Surface;
use Sub::Frequency;
use SDLx::Widget::Menu;

sub startup {
    my ($self, $app) = @_;

    my $sound = SDLx::Audio->new->load(
        horn1 => 'data/car_horn1.wav',
        horn2 => 'data/car_horn2.wav',
    );

    my $logo = SDLx::Surface->load('data/opening.png');

    my $menu = SDLx::Widget::Menu->new(
        font    => 'data/font.ttf',
        topleft => [440,340],
        font_size => 40,
    )->items(
        'New Game' => \&play,
        'Quit'     => \&quit,
    );

    event 'key_down' => sub {
        my ($key, $event) = @_;
        $menu->event_hook( $event );
    };

    show {
        my ($delta, $app) = @_;

        $logo->blit($app);
        $menu->render( $app );

        $app->update;
    };

    show {
        with_probability 0.1 => sub {
            $sound->play('horn1');
        };

        with_probability 0.005 => sub {
            $sound->play('horn2');
        };
    };

}

sub play {
    load 'Level';
}

sub quit {
    exit;
}


'all your base are belong to us.'
