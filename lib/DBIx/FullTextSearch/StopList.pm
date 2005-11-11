package DBIx::FullTextSearch::StopList;
use strict;

use Carp;

sub create_default {
  my ($class, $dbh, $TABLE, $language) = @_;

  croak("Error: no language specified") unless $language;

  $language = lc $language;

  my @stopList;

  if($language eq 'english'){
    @stopList = qw/ a about after all also an and any are as at be because been but by can co corp could for from had has have he her his if in inc into is it its last more most mr mrs ms mz no not of on one only or other out over s says she so some such than that the their there they this to up was we were when which who will with would /;
   } elsif ($language eq 'czech'){
     @stopList = qw/ a aby ale ani a� bude by byl byla bylo b�t co �i dal�� do i jak jako je jeho jejich jen je�t� ji� jsem jsme jsou k kde kdy� korun kter� kter� kter� kte�� let mezi m� m��e na nebo nen� ne� o od pak po podle pouze pro proti prvn� p�ed p�i roce roku �ekl s se si sv� tak tak� tedy to tom t�m u u� v ve v�ak z za ze �e/;
  } elsif ($language eq 'danish'){
    @stopList = qw/ af aldrig alle altid bagved De de der du efter eller en endnu et f� fjernt for foran fra gennem god han her hos hovfor hun hurtig hvad hvem hvon�r hvor hvordan hvorhen I i imod ja jeg langsom lidt mange m�ske med meget mellem mere mindre n�r nede nej nok nu og oppe p� rask sammen temmelig til uden udenfor under ved vi /;
  } elsif ($language eq 'dutch'){
    @stopList = qw/ aan aangaande aangezien achter achterna afgelopen al aldaar aldus alhoewel alias alle allebei alleen alsnog altijd altoos ander andere anders anderszins behalve behoudens beide beiden ben beneden bent bepaald betreffende bij binnen binnenin boven bovenal bovendien bovengenoemd bovenstaand bovenvermeld buiten daar daarheen daarin daarna daarnet daarom daarop daarvanlangs dan dat de die dikwijls dit door doorgaand dus echter eer eerdat eerder eerlang eerst elk elke en enig enigszins enkel er erdoor even eveneens evenwel gauw gedurende geen gehad gekund geleden gelijk gemoeten gemogen geweest gewoon gewoonweg haar had hadden hare heb hebben hebt heeft hem hen het hierbeneden hierboven hij hoe hoewel hun hunne ik ikzelf in inmiddels inzake is jezelf jij jijzelf jou jouw jouwe juist jullie kan klaar kon konden krachtens kunnen kunt later liever maar mag meer met mezelf mij mijn mijnent mijner mijzelf misschien mocht mochten moest moesten moet moeten mogen na naar nadat net niet noch nog nogal nu of ofschoon om omdat omhoog omlaag omstreeks omtrent omver onder ondertussen ongeveer ons onszelf onze ook op opnieuw opzij over overeind overigens pas precies reeds rond rondom sedert sinds sindsdien slechts sommige spoedig steeds tamelijk tenzij terwijl thans tijdens toch toen toenmaals toenmalig tot totdat tussen uit uitgezonderd vaak van vandaan vanuit vanwege veeleer verder vervolgens vol volgens voor vooraf vooral vooralsnog voorbij voordat voordezen voordien voorheen voorop vooruit vrij vroeg waar waarom wanneer want waren was wat weer weg wegens wel weldra welk welke wie wiens wier wij wijzelf zal ze zelfs zichzelf zij zijn zijne zo zodra zonder zou zouden zowat zulke zullen zult /;
  } elsif ($language eq 'finnish'){
    @stopList = qw/ aina alla ansiosta ehk� ei enemm�n ennen etessa haikki h�n he hitaasti hoikein hyvin ilman ja j�lkeen jos kanssa kaukana kenties keskell� kesken koskaan kuinkan kukka kyll� kylliksi l�hell� l�pi liian lla lla luona me mik� miksi milloin milloinkan min� miss� miten nopeasti nyt oikea oikealla paljon siell� sin� ssa sta suoraan tai takana takia tarpeeksi t�ss� te ulkopuolella v�h�n vahemm�n vasen vasenmalla vastan viel� vieress� yhdess� yl�s /;
  } elsif ($language eq 'french'){
    @stopList = qw/ a � afin ailleurs ainsi alors apr�s attendant au aucun aucune au-dessous au-dessus aupr�s auquel aussi aussit�t autant autour aux auxquelles auxquels avec beaucoup �a ce ceci cela celle celles celui cependant certain certaine certaines certains ces cet cette ceux chacun chacune chaque chez combien comme comment concernant dans de dedans dehors d�j� del� depuis des d�s desquelles desquels dessus donc donn� dont du duquel durant elle elles en encore entre et �taient �tait �tant etc eux furent gr�ce hormis hors ici il ils jadis je jusqu jusque la l� laquelle le lequel les lesquelles lesquels leur leurs lors lorsque lui ma mais malgr� me m�me m�mes mes mien mienne miennes miens moins moment mon moyennant ne ni non nos notamment notre n�tre notres n�tres nous nulle nulles on ou o� par parce parmi plus plusieurs pour pourquoi pr�s puis puisque quand quant que quel quelle quelque quelques-unes quelques-uns quelqu''un quelqu''une quels qui quiconque quoi quoique sa sans sauf se selon ses sien sienne siennes siens soi soi-m�me soit sont suis sur ta tandis tant te telle telles tes tienne tiennes tiens toi ton toujours tous toute toutes tr�s trop tu un une vos votre v�tre v�tres vous vu y /;
  } elsif ($language eq 'german'){
    @stopList = qw/ ab aber allein als also am an auch auf aus au�er bald bei beim bin bis bi�chen bist da dabei dadurch daf�r dagegen dahinter damit danach daneben dann daran darauf daraus darin dar�ber darum darunter das da� dasselbe davon davor dazu dazwischen dein deine deinem deinen deiner deines dem demselben den denn der derselben des desselben dessen dich die dies diese dieselbe dieselben diesem diesen dieser dieses dir doch dort du ebenso ehe ein eine einem einen einer eines entlang er es etwa etwas euch euer eure eurem euren eurer eures f�r f�rs ganz gar gegen genau gewesen her herein herum hin hinter hintern ich ihm ihn Ihnen ihnen ihr Ihre ihre Ihrem ihrem Ihren ihren Ihrer ihrer Ihres ihres im in ist ja je jedesmal jedoch jene jenem jenen jener jenes kaum kein keine keinem keinen keiner keines man mehr mein meine meinem meinen meiner meines mich mir mit nach nachdem n�mlich neben nein nicht nichts noch nun nur ob ober obgleich oder ohne paar sehr sei sein seine seinem seinen seiner seines seit seitdem selbst sich Sie sie sind so sogar solch solche solchem solchen solcher solches sondern sonst soviel soweit �ber um und uns unser unsre unsrem unsren unsrer unsres vom von vor w�hrend war w�re w�ren warum was wegen weil weit welche welchem welchen welcher welches wem wen wenn wer weshalb wessen wie wir wo womit zu zum zur zwar zwischen zwischens /;
  } elsif ($language eq 'italian'){
    @stopList = qw/ a affinch� agl'' agli ai al all'' alla alle allo anzich� avere bens� che chi cio� come comunque con contro cosa da dach� dagl'' dagli dai dal dall'' dalla dalle dallo degl'' degli dei del dell'' delle dello di dopo dove dunque durante e egli eppure essere essi finch� fino fra giacch� gl'' gli grazie I il in inoltre io l'' la le lo loro ma mentre mio ne neanche negl'' negli nei nel nell'' nella nelle nello nemmeno neppure noi nonch� nondimeno nostro o onde oppure ossia ovvero per perch� perci� per� poich� prima purch� quand''anche quando quantunque quasi quindi se sebbene sennonch� senza seppure si siccome sopra sotto su subito sugl'' sugli sui sul sull'' sulla sulle sullo suo talch� tu tuo tuttavia tutti un una uno voi vostr/;
  } elsif ($language eq 'portuguese'){
    @stopList = qw/ a abaixo adiante agora ali antes aqui at� atras bastante bem com como contra debaixo demais depois depressa devagar direito e ela elas �le eles em entre eu fora junto longe mais menos muito n�o ninguem n�s nunca onde ou para por porque pouco pr�ximo qual quando quanto que quem se sem sempre sim sob sobre talvez todas todos vagarosamente voc� voc�s /;
  } elsif ($language eq 'spanish'){
    @stopList = qw/ a ac� ah� ajena ajenas ajeno ajenos al algo alg�n alguna algunas alguno algunos all� all� aquel aquella aquellas aquello aquellos aqu� cada cierta ciertas cierto ciertos como c�mo con conmigo consigo contigo cualquier cualquiera cualquieras cuan cu�n cuanta cu�nta cuantas cu�ntas cuanto cu�nto cuantos cu�ntos de dejar del dem�s demasiada demasiadas demasiado demasiados el �l ella ellas ellos esa esas ese esos esta estar estas este estos hacer hasta jam�s junto juntos la las lo los mas m�s me menos m�a mientras m�o misma mismas mismo mismos mucha muchas much�sima much�simas much�simo much�simos mucho muchos muy nada ni ninguna ningunas ninguno ningunos no nos nosotras nosotros nuestra nuestras nuestro nuestros nunca os otra otras otro otros para parecer poca pocas poco pocos por porque que qu� querer quien qui�n quienes quienesquiera quienquiera ser si s� siempre s�n Sr Sra Sres Sta suya suyas suyo suyos tal tales tan tanta tantas tanto tantos te tener ti toda todas todo todos tomar t� tuya tuyo un una unas unos usted ustedes varias varios vosotras vosotros vuestra vuestras vuestro vuestros y yo /;
  } elsif ($language eq 'swedish'){
    @stopList = qw/ ab aldrig all alla alltid �n �nnu �nyo �r att av avser avses bakom bra bredvid d� d�r de dem den denna deras dess det detta du efter efter�t eftersom ej eller emot en ett fast�n f�r fort framf�r fr�n genom gott hamske han h�r hellre hon hos hur i in ingen innan inte ja jag l�ngsamt l�ngt lite man med medan mellan mer mera mindre mot myckett n�r n�ra nej nere ni nu och oksa om �ver p� s� s�dan sin skall som till tillr�ckligt tillsammans trotsatt under uppe ut utan utom vad v�l var varf�r vart varth�n vem vems vi vid vilken /;
  }

  croak("Error: language $language is not a supported") unless @stopList;

  my $sl = $class->create_empty($dbh, $TABLE);

  $sl->add_stop_word(\@stopList);
  return $sl;
}

sub create_empty {
  my ($class, $dbh, $name) = @_;

  my $table = $name . '_stoplist';

  my $SQL = qq{
CREATE TABLE $table
(word VARCHAR(255) PRIMARY KEY)
};
  
  $dbh->do($SQL) or croak "Can't create table $table: " . $dbh->errstr;

  my $self = {};
  $self->{'dbh'} = $dbh;
  $self->{'name'} = $name;
  $self->{'table'} = $table;
  $self->{'stoplist'} = {};
  bless $self, $class;
  return $self;
}

sub open {
  my ($class, $dbh, $name) = @_;

  my $table = $name . '_stoplist';

  my $self = {};
  $self->{'dbh'} = $dbh;
  $self->{'name'} = $name;
  $self->{'table'} = $table;
  $self->{'stoplist'} = {};
  bless $self, $class;

  # load stoplist into a hash
  my $SQL = qq{
SELECT word FROM $table
};
  my $ary_ref = $dbh->selectcol_arrayref($SQL) or croak "Can't load stoplist from $table: " . $dbh->errstr;
  for (@$ary_ref){
    $self->{'stoplist'}->{$_} = 1;
  }

  return $self;
}

sub drop {
  my $self = shift;
  my $dbh = $self->{'dbh'};
  my $table = $self->{'table'};
  my $SQL = qq{
DROP table $table
};
  $dbh->do($SQL) or croak "Can't drop table $table: " . $dbh->errstr;
  $self->{'stoplist'} = {};
}

sub empty {
  my $self = shift;
  my $dbh = $self->{'dbh'};
  my $table = $self->{'table'};
  my $SQL = qq{
DELETE FROM $table
};
  $dbh->do($SQL) or croak "Can't empty table $table: " . $dbh->errstr;
  $self->{'stoplist'} = {};
}

sub add_stop_word {
  my ($self, $words) = @_;
  my $dbh = $self->{'dbh'};

  $words = [ $words ] unless ref($words) eq 'ARRAY';

  my @new_stop_words;

  for my $word (@$words){
    next if $self->is_stop_word($word);
    push @new_stop_words, $word;
    $self->{'stoplist'}->{lc($word)} = 1;
  }
  my $SQL = "INSERT INTO $self->{'table'} (word) VALUES " . join(',', ('(?)') x @new_stop_words);
  $dbh->do($SQL,{},@new_stop_words);
}

sub remove_stop_word {
  my ($self, $words) = @_;
  my $dbh = $self->{'dbh'};

  $words = [ $words ] unless ref($words) eq 'ARRAY';

  my $SQL = qq{
DELETE FROM $self->{'table'} WHERE word=?
};

  my $sth = $dbh->prepare($SQL);

  my $stoplist = $self->{'stoplist'};

  for my $word (@$words){
    next unless $self->is_stop_word($word);
    $sth->execute($word);
    delete $stoplist->{lc($word)};
  }
}

sub is_stop_word {
  exists shift->{'stoplist'}->{lc($_[0])};
}

1;

__END__

=head1 NAME

DBIx::FullTextSearch::StopList - Stopwords for DBIx::FullTextSearch

=head1 SYNOPSIS

  use DBIx::FullTextSearch::StopList;
  # connect to database (regular DBI)
  my $dbh = DBI->connect('dbi:mysql:database', 'user', 'passwd');

  # create a new empty stop word list
  my $sl1 = DBIx::FullTextSearch::StopList->create_empty($dbh, 'sl_web_1');

  # or create a new one with default stop words
  my $sl2 = DBIx::FullTextSearch::StopList->create_default($dbh, 'sl_web_2', 'english');

  # or open an existing one
  my $sl3 = DBIx::FullTextSearch::StopList->open($dbh, 'sl_web_3');

  # add stop words
  $sl1->add_stop_word(['a','in','on','the']);

  # remove stop words
  $sl2->remove_stop_word(['be','because','been','but','by']);

  # check if word is in stoplist
  $bool = $sl1->is_stop_word('in');

  # empty stop words
  $sl3->empty;

  # drop stop word table
  $sl2->drop;

=head1 DESCRIPTION

DBIx::FullTextSearch::StopList provides stop lists that can be used -L<DBIx::FullTextSearch>.
StopList objects can be reused accross several FullTextSearch objects.

=head1 METHODS

=over 4

=head2 CONSTRUCTERS

=item create_empty

  my $sl = DBIx::FullTextSearch::StopList->create_empty($dbh, $sl_name);

This class method creates a new StopList object.

=item create_default

  my $sl = DBIx::FullTextSearch::StopList->create_default($dbh, $sl_name, $language);

This class method creates a new StopList object, with default words loaded in for the
given language.  Supported languages include Czech, Danish, Dutch, English, Finnish, French,
German, Italian, Portuguese, Spanish, and Swedish.

=item open

  my $sl = DBIx::FullTextSearch::StopList->open($dbh, $sl_name);

Opens and returns StopList object

=head2 OBJECT METHODS

=item add_stop_word

  $sl->add_stop_word(\@stop_words);

Adds stop words to StopList object.  Expects array reference as argument.

=item remove_stop_word

  $sl->remove_stop_word(\@stop_words);

Remove stop words from StopList object.  

=item is_stop_word

  $bool = $sl->is_stop_word($stop_word);

Returns true iff stop_word is StopList object

=item empty

  $sl->empty;

Removes all stop words in StopList object.

=item drop

  $sl->drop;

Removes table associated with the StopList object.

=back

=head1 AUTHOR

T.J. Mather, tjmather@tjmather.com,
http://www.tjmather.com/

=head1 COPYRIGHT

All rights reserved. This package is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBIx::FullTextSearch>
