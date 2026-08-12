import 'package:CiliCili/models/common/enum_with_label.dart';
import 'package:CiliCili/pages/common/common_controller.dart';
import 'package:CiliCili/pages/hot/controller.dart';
import 'package:CiliCili/pages/hot/view.dart';
import 'package:CiliCili/pages/live/controller.dart';
import 'package:CiliCili/pages/live/view.dart';
import 'package:CiliCili/pages/pgc/controller.dart';
import 'package:CiliCili/pages/pgc/view.dart';
import 'package:CiliCili/pages/rank/controller.dart';
import 'package:CiliCili/pages/rank/view.dart';
import 'package:CiliCili/pages/rcmd/controller.dart';
import 'package:CiliCili/pages/rcmd/view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum HomeTabType implements EnumWithLabel {
  live('直播'),
  rcmd('推荐'),
  hot('热门'),
  rank('分区'),
  bangumi('番剧'),
  cinema('影视'),
  ;

  @override
  final String label;
  const HomeTabType(this.label);

  ScrollOrRefreshMixin Function() get ctr => switch (this) {
    HomeTabType.live => Get.find<LiveController>,
    HomeTabType.rcmd => Get.find<RcmdController>,
    HomeTabType.hot => Get.find<HotController>,
    HomeTabType.rank => Get.find<RankController>,
    HomeTabType.bangumi ||
    HomeTabType.cinema => () => Get.find<PgcController>(tag: name),
  };

  Widget get page => switch (this) {
    HomeTabType.live => const LivePage(),
    HomeTabType.rcmd => const RcmdPage(),
    HomeTabType.hot => const HotPage(),
    HomeTabType.rank => const RankPage(),
    HomeTabType.bangumi => const PgcPage(tabType: HomeTabType.bangumi),
    HomeTabType.cinema => const PgcPage(tabType: HomeTabType.cinema),
  };
}
