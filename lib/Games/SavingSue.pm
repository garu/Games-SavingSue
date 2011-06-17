package Games::SavingSue;
use Avenger title => 'Saving Sue';
use SDLx::Audio;

my $bgmusic = SDLx::Audio->new->music('data/bgmusic.ogg');
$bgmusic->play_music;

start 'Menu';

'all your base are belong to us.'
