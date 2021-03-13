################## データ保存 ##################
use strict;
#use warnings;
use utf8;

sub data_calc {
  my %pc = %{$_[0]};

  ### レベル・成長 --------------------------------------------------
  ## 履歴から 
  $pc{'enduranceGrow'}  = $pc{'endurancePreGrow'};
  $pc{'initiativeGrow'} = $pc{'initiativePreGrow'};
  
  foreach my $i (0 .. $pc{'historyNum'}){
    if   ($pc{"history${i}Grow"} eq 'endurance' ) { $pc{'enduranceGrow'}  += 5; }
    elsif($pc{"history${i}Grow"} eq 'initiative') { $pc{'initiativeGrow'} += 2; }
    $pc{'level'} = 1 + ($pc{"enduranceGrow"} / 5) + ($pc{"initiativeGrow"} / 2);
  }

  ### 能力値 --------------------------------------------------
  if   ($pc{'factor'} eq '人間'){
    $pc{'endurance'}  = $pc{'statusMain1'} * 2 + $pc{'statusMain2'};
    $pc{'initiative'} = $pc{'statusMain2'} + 10;
  }
  elsif($pc{'factor'} eq '吸血鬼'){
    $pc{'endurance'}  = $pc{'statusMain1'} + 20;
    $pc{'initiative'} = $pc{'statusMain2'} + 4;
  }
  $pc{'endurance'}  += $pc{'enduranceAdd'}  + $pc{'enduranceGrow'};
  $pc{'initiative'} += $pc{'initiativeAdd'} + $pc{'initiativeGrow'};

  ### 0を消去 --------------------------------------------------
  #foreach (
  #  '',
  #){
  #  delete $pc{$_} if !$pc{$_};
  #}

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{'words'}       =~ s/\r\n?|\n/<br>/g;
  $pc{'freeNote'}    =~ s/\r\n?|\n/<br>/g;
  $pc{'freeHistory'} =~ s/\r\n?|\n/<br>/g;
  $pc{'chatPalette'} =~ s/\r\n?|\n/<br>/g;
  $pc{'scarNote'}    =~ s/\r\n?|\n/<br>/g;

  ### newline --------------------------------------------------
  my($name, undef) = split(/:/,$pc{'characterName'});
  my($aka,  undef) = split(/:/,$pc{'aka'});
  my $charactername = ($aka?"“$aka”":"").$name;
  $charactername =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $::newline = "$pc{'id'}<>$::file<>".
               "$pc{'birthTime'}<>$::now<>$charactername<>$pc{'playerName'}<>$pc{'group'}<>".
               "$pc{'factor'}<>$pc{'factorCore'}<>$pc{'factorStyle'}<>".
               "$pc{'gender'}<>$pc{'age'}<>$pc{'ageApp'}<>".
               "$pc{'belong'}<>$pc{'missing'}<>".
               "$pc{'level'}<>".
               
               "$pc{'sessionTotal'}<>$pc{'image'}<> $pc{'tags'} <>$pc{'hide'}<><>";

  return %pc;
}

1;