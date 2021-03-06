################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_races;
require $set::data_items;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_item, utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### キャラクターデータ読み込み #######################################################################
our %pc = pcDataGet();

### 閲覧禁止データ ###################################################################################
if($::in{'checkView'}){ $::LOGIN_ID = ''; }

if($pc{'forbidden'} && (getfile($::in{'id'},'',$::LOGIN_ID))[0]){
  $pc{'forbiddenAuthor'} = 1;
}
elsif($pc{'forbidden'}){
  my $author = $pc{'author'};
  my $protect   = $pc{'protect'};
  my $forbidden = $pc{'forbidden'};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{'itemName'}   = noiseText(6,14);
    $pc{'tags'} = '';
  }
  
  $pc{'price'}      = noiseText(1,8);
  $pc{'reputation'} = noiseText(2,3);
  $pc{'shape'}      = noiseText(8,20);
  $pc{'category'}   = noiseText(2,8);
  $pc{'age'}        = noiseText(2,6);
  $pc{'summary'}    = noiseText(8,28);
  
  $pc{'effects'} = '';
  foreach(1..int(rand 4)+1){
    $pc{'effects'} .= noiseText(6,18)."\n";
    $pc{'effects'} .= '　'.noiseText(18,40)."\n";
    $pc{'effects'} .= '　'.noiseText(18,40)."\n" if(int rand 2);
    $pc{'effects'} .= "\n";
  }
  
  $pc{'author'} = $author;
  $pc{'protect'} = $protect;
  $pc{'forbidden'} = $forbidden;
  $pc{'forbiddenMode'} = 1;
}

### 置換前出力 #######################################################################################
$SHEET->param("rawName" => $pc{'itemName'});

### 置換 #############################################################################################
foreach (keys %pc) {
  if($_ =~ /^(?:effects|description)$/){
    $pc{$_} = tag_unescape_lines($pc{$_});
  }
  $pc{$_} = tag_unescape($pc{$_},$pc{'oldSignConv'});
}
$pc{'effects'} =~ s/<br>/\n/gi;
$pc{'effects'} =~ s/^●(.*?)$/<\/p><h3>●$1<\/h3><p>/gim;
if($::SW2_0){
  $pc{'effects'} =~ s/^((?:[○◯〇＞▶〆☆≫»□☑🗨▽▼]|&gt;&gt;)+)(.*?)([ 　]|$)/"<\/p><h5>".&text_convert_icon($1)."$2<\/h5><p>".$3;/egim;
} else {
  $pc{'effects'} =~ s/^((?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+)(.*?)([ 　]|$)/"<\/p><h5>".&text_convert_icon($1)."$2<\/h5><p>".$3;/egim;
}
$pc{'effects'} =~ s/\n+<\/p>/<\/p>/gi;
$pc{'effects'} =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
$pc{'effects'} = "<p>$pc{'effects'}</p>";
$pc{'effects'} =~ s/<p><\/p>//gi;
$pc{'effects'} =~ s/\n/<br>/gi;

### 出力準備 #########################################################################################
### データ全体 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}
### ID / URL--------------------------------------------------
$SHEET->param("id" => $::in{'id'});

if($::in{'url'}){
  $SHEET->param("convertMode" => 1);
  $SHEET->param("convertUrl" => $::in{'url'});
}

### 魔法の武器アイコン --------------------------------------------------
$SHEET->param("magic" => ($pc{'magic'} ? "<img class=\"i-icon\" src=\"${set::icon_dir}wp_magic.png\">" : ''));

### カテゴリ --------------------------------------------------
$pc{'category'} =~ s/[ 　]/<hr>/g;
$SHEET->param("category" => $pc{'category'});

### 武器 --------------------------------------------------
my @weapons;
foreach (1 .. 3){
  next if $pc{'weapon'.$_.'Usage'}.$pc{'weapon'.$_.'Reqd'}.
          $pc{'weapon'.$_.'Acc'}.$pc{'weapon'.$_.'Rate'}.$pc{'weapon'.$_.'Crit'}.
          $pc{'weapon'.$_.'Dmg'}.$pc{'weapon'.$_.'Note'}
          eq '';
  push(@weapons, {
    "USAGE"    => $pc{'weapon'.$_.'Usage'},
    "REQD"     => $pc{'weapon'.$_.'Reqd'},
    "ACC"      => $pc{'weapon'.$_.'Acc'},
    "RATE"     => $pc{'weapon'.$_.'Rate'},
    "CRIT"     => $pc{'weapon'.$_.'Crit'},
    "DMG"      => $pc{'weapon'.$_.'Dmg'},
    "NOTE"     => $pc{'weapon'.$_.'Note'},
  } );
}
$SHEET->param(WeaponData => \@weapons) if !$pc{'forbiddenMode'};

### 防具 --------------------------------------------------
my @armours;
foreach (1 .. 3){
  next if $pc{'armour'.$_.'Usage'}.$pc{'armour'.$_.'Reqd'}.
          $pc{'armour'.$_.'Acc'}.$pc{'armour'.$_.'Def'}.$pc{'armour'.$_.'Note'}
          eq '';
  push(@armours, {
    "USAGE"    => $pc{'armour'.$_.'Usage'},
    "REQD"     => $pc{'armour'.$_.'Reqd'},
    "EVA"      => $pc{'armour'.$_.'Eva'},
    "DEF"      => $pc{'armour'.$_.'Def'},
    "NOTE"     => $pc{'armour'.$_.'Note'},
  } );
}
$SHEET->param(ArmourData => \@armours) if !$pc{'forbiddenMode'};

### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{'tags'})){
    push(@tags, {
      "URL"  => uri_escape_utf8($_),
      "TEXT" => $_,
    });
}
$SHEET->param(Tags => \@tags);


### バックアップ --------------------------------------------------
if($::in{'id'}){
  opendir(my $DIR,"${set::item_dir}${main::file}/backup");
  my @backlist = readdir($DIR);
  closedir($DIR);
  my @backup;
  foreach (reverse sort @backlist) {
    if ($_ =~ s/\.cgi//) {
      my $url = $_;
      $_ =~ s/^([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})-([0-9]{2})$/$1 $2\:$3/;
      push(@backup, {
        "NOW"  => ($url eq $::in{'backup'} ? 1 : 0),
        "URL"  => $url,
        "DATE" => $_,
      });
    }
  }
  $SHEET->param(Backup => \@backup);
}

### パスワード要求 --------------------------------------------------
$SHEET->param(ReqdPassword => (!$pc{'protect'} || $pc{'protect'} eq 'password' ? 1 : 0) );

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{'forbidden'} eq 'all' && $pc{'forbiddenMode'}){
  $SHEET->param(itemNameTitle => '非公開データ');
}
else {
  $SHEET->param(itemNameTitle => tag_delete name_plain $pc{'itemName'});
}

### 画像 --------------------------------------------------
$pc{'imageUpdateTime'} = $pc{'updateTime'};
$pc{'imageUpdateTime'} =~ s/[\-\ \:]//g;
$SHEET->param("imageSrc" => "${set::item_dir}${main::file}/image.$pc{'image'}?$pc{'imageUpdateTime'}");

### バージョン等 --------------------------------------------------
$SHEET->param("ver" => $::ver);
$SHEET->param("coreDir" => $::core_dir);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $SHEET->output;

1;