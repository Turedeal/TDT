//
//  PHFreeIdentifyVC.m
//  PonHu
//
//  Created by Andy on 2018/6/19.
//  Copyright © 2018年 Andy. All rights reserved.
//

#import "PHFreeIdentifyVC.h"
#import "PHFreeIdentifyCollectionCell.h"
#import "PHPicIdentifyCell.h"
#import "PHMyIdentifyView.h"
#import "PHFreeIdentifyView.h"
#import "PHFreeIdentiftyPicVC.h"
#import "PHFreeIdentiftyRealVC.h"

#define SWITCH_HEIGHT     mas_height(200)

#define k_itemSize        mas_height(181)
#define FOOT_HEIGHT       mas_height(80)

#define k_BANNER_CELL              1
#define k_IDENTIFY_CELL            2

@interface PHFreeIdentifyVC ()<MECollectionLayoutDelegate>
@property (nonatomic, strong) MECollectionLayout *layout;
@property (nonatomic, strong) MECollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray *markArray;
@property (nonatomic, strong) PHPicIdentifyModel *model;

@property (nonatomic, strong) NSMutableArray *productArray;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) NSInteger productCount;
@property (nonatomic, assign) BOOL isLoadMore;
@property (nonatomic, strong) NSMutableArray *statusFrames;

@property (nonatomic, strong) PHFreeIdentifyTitleView *titleView;
@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, strong) PHFreeIdentifyView *popView;
@property (nonatomic, assign) PHAppraiserType type;

@property (nonatomic, assign) BOOL isOpenSwitch;
@property (nonatomic, strong) PHIdentityBtnView *switchView;
@property (nonatomic, strong) PHIdentityPopView *identityPopView;
@end

@implementation PHFreeIdentifyVC

- (NSMutableArray *)statusFrames{
    if (_statusFrames==nil){
        _statusFrames = [NSMutableArray array];
    }
    return _statusFrames;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _isOpenSwitch = YES;
    _isEnabled = YES;
    _type = PHAppraiserType_All;
    _isLoadMore = YES;
    _pageIndex = 1;
    _productArray = [NSMutableArray array];
    _markArray = [NSMutableArray array];
    
    _layout = [[MECollectionLayout alloc] init:UICollectionViewScrollDirectionVertical itemSize:CGSizeMake(k_itemSize, k_itemSize)];
    _layout.layout_delegate = self;
    
    _collectionView = [[MECollectionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, HIDE_TAB_BAR_HEIGHT) collectionViewLayout:_layout delegate:self dataSource:self];
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.backgroundView = ({
        MENotDataView *failedView = [[MENotDataView alloc] initWithFrame:self.view.frame];
        failedView.textBgColor = METableBgColor;
        failedView.placeholderString = @"暂无鉴定数据~";
        failedView;
    });
    _collectionView.backgroundView.hidden = YES;
    [self.view addSubview:_collectionView];
    _collectionView.alpha = 0;
    
    [_collectionView registerClass:[PHFreeIdentifyCollectionCell class] forCellWithReuseIdentifier:@"freeIdentifyCollectionCell"];
    [_collectionView registerClass:[PHFreeIdentifyHeadView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"freeIdentifyHeadView"];
    [_collectionView registerClass:[PHFreeIdentifyFootView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"freeIdentifyFootView"];
    
    [_collectionView registerClass:[PHPicIdentifyCell class] forCellWithReuseIdentifier:@"picIdentifyCell"];
    [_collectionView registerClass:[PicIdentifyHeadView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"picIdentifyHeadReusableView"];
    [_collectionView registerClass:[PicIdentifyFootView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"picIdentifyFootReusableView"];
    
    
    WS(ws);
    [_collectionView setDownload:^{
        [ws initLoadData];
    }];
    [_collectionView setPullDownload:^{
        [ws getPicIdentifyListByPage];
    }];
    [_collectionView.mj_header beginRefreshing];
    
    [self barButtonItem];
}

- (void)getPicIdentifyList{
    
    NSDictionary *params = @{@"p"           : @(_pageIndex),
                             @"rows"        : @(PAGE_NUMBER),
                             @"result"      : @(_type)};
    
    [AFSharedManager postRequest:k_FREE_IDENTIFITY dictionaryParams:params showHUD:self.view finishBlock:^(NSDictionary *finishData) {
        [_collectionView.mj_header endRefreshing];
        [_collectionView.mj_footer resetNoMoreData];
        
        [_markArray removeAllObjects];
        [self.statusFrames removeAllObjects];
        [_productArray removeAllObjects];
        
        _model = [PHPicIdentifyModel modelWithDictionary:finishData];
        [_productArray addObjectsFromArray:_model.list];
        _productCount = _productArray.count;
    
        if (_model.is_expert == 1 && _isEnabled)
        {
            _isEnabled = NO;
            self.navigationItem.titleView = _titleView;
        }
        
        if (_model.banner.count > 0)
        {
            [_markArray addObject:@(k_BANNER_CELL)];
        }
        
        if (_model.list.count < PAGE_NUMBER)
            _isLoadMore = NO;
        else
            _isLoadMore = YES;
        
        for (PicIdentifyModel *obj in _productArray)
        {
            PicSizeModel *descModel = [[PicSizeModel alloc] init];
            descModel.content =  obj.desc;
            [self.statusFrames addObject:descModel];
            
            [_markArray addObject:@(k_IDENTIFY_CELL)];
        }
        
        if (_model.banner.count > 0)
            ++_productCount;
        
        if (_productCount == 0)
            _collectionView.backgroundView.hidden = NO;
        else
            _collectionView.backgroundView.hidden = YES;
        
        [_collectionView reloadData];
        [UIView animateWithDuration:ANIMATE_DURATION animations:^{
            _collectionView.alpha = 1;
        }];
        if (_isOpenSwitch)
            [_switchView show];
    } failedBlock:^(NSError *error) {
        [_collectionView.mj_header endRefreshing];
        [_collectionView.mj_footer endRefreshing];
        
        [UIView animateWithDuration:ANIMATE_DURATION animations:^{
            _collectionView.alpha = 1;
        }];
    }];
}

- (void)getPicIdentifyListByPage {
    if (_isLoadMore)
        _pageIndex += 1;
    else{
        [_collectionView.mj_footer endRefreshingWithNoMoreData];
        return;
    }
    
    NSDictionary *params = @{@"p"           : @(_pageIndex),
                             @"rows"        : @(PAGE_NUMBER),
                             @"result"      : @(_type)};
    
    [AFSharedManager postRequest:k_FREE_IDENTIFITY dictionaryParams:params showHUD:self.view finishBlock:^(NSDictionary *finishData) {
        [_collectionView.mj_footer endRefreshing];
        if(_pageIndex == 1)
        {
            [_markArray removeAllObjects];
            [_productArray removeAllObjects];
            [self.statusFrames removeAllObjects];
        }
        
        PHPicIdentifyModel *model = [PHPicIdentifyModel modelWithDictionary:finishData];
        [_productArray addObjectsFromArray:model.list];
        _productCount = _productArray.count;
        
        if (model.list.count < PAGE_NUMBER)
            _isLoadMore = NO;
        
        for (PicIdentifyModel *obj in model.list)
        {
            PicSizeModel *descModel = [[PicSizeModel alloc] init];
            descModel.content =  obj.desc;
            [self.statusFrames addObject:descModel];
            
            [_markArray addObject:@(k_IDENTIFY_CELL)];
        }
        if (model.banner.count > 0)
            ++_productCount;
        
        [_collectionView reloadData];
    } failedBlock:^(NSError *error) {
        [_collectionView.mj_header endRefreshing];
        [_collectionView.mj_footer endRefreshing];
    }];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger type = [_markArray[indexPath.section] integerValue];
    if (type == k_BANNER_CELL)
    {
        PHFreeIdentifyCollectionCell *cell = (PHFreeIdentifyCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"freeIdentifyCollectionCell" forIndexPath:indexPath];
        return cell;
    }
    
    PicIdentifyModel *model = _productArray[indexPath.section-1];
    PHPicIdentifyCell *cell = (PHPicIdentifyCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"picIdentifyCell" forIndexPath:indexPath];
    cell.urlString = model.picarr[indexPath.row];
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return _productCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger type = [_markArray[section] integerValue];
    if (type == k_BANNER_CELL)
        return 0;
    
    PicIdentifyModel *model = _productArray[section-1];
    return model.picarr.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    WS(ws);
    NSInteger type = [_markArray[indexPath.section] integerValue];
    if (type == k_BANNER_CELL)
    {
        if (kind == UICollectionElementKindSectionHeader)
        {
            PHFreeIdentifyHeadView *headView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"freeIdentifyHeadView" forIndexPath:indexPath];
            headView.adBanner = _model.banner;
            return headView;
        }
        else
        {
            PHFreeIdentifyFootView *footView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"freeIdentifyFootView" forIndexPath:indexPath];
            footView.numString = _model.excount;
            return footView;
        }
    }
    
    if (kind == UICollectionElementKindSectionHeader)
    {
        PicIdentifyHeadView *headView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"picIdentifyHeadReusableView" forIndexPath:indexPath];
        headView.updateIdentifyBlock = ^{
            [ws initLoadData];
        };
        headView.model = _productArray[indexPath.section-1];
        return headView;
    }
    else
    {
        PicIdentifyFootView *footView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"picIdentifyFootReusableView" forIndexPath:indexPath];
        footView.updateIdentifyBlock = ^{
            [ws initLoadData];
        };
        footView.model = _productArray[indexPath.section-1];
        return footView;
    }
}

- (void)initLoadData{
    _pageIndex = 1;
    [self getPicIdentifyList];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(k_itemSize, k_itemSize);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    NSInteger type = [_markArray[section] integerValue];
    if (type == k_BANNER_CELL)
        return CGSizeMake(SCREEN_WIDTH, mas_height(300));
        
    PicSizeModel *model = self.statusFrames[section-1];
    return CGSizeMake(SCREEN_WIDTH, model.contentHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
    NSInteger type = [_markArray[section] integerValue];
    if (type == k_BANNER_CELL)
        return CGSizeMake(SCREEN_WIDTH, mas_height(140));
    
    return CGSizeMake(SCREEN_WIDTH, FOOT_HEIGHT);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, mas_height(154), 0, MARGIN);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return mas_height(10);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{

}


/**
 鉴定师
 */
- (void)barButtonItem{
    self.titleString = @"免费鉴定";
    
    WS(ws);
    _titleView = [[PHFreeIdentifyTitleView alloc] initWithFrame:CGRectMake(0, 0, 140, 44)];
    _titleView.titleString = @"全部";
    _titleView.showBlock = ^{
        [ws.popView popShow];
    };
    
    [self.view addSubview:self.popView];
    self.popView.didSelectRowBlock = ^(PHAppraiserType type, NSString *titleString) {
        [ws didSelectRowBlock:type title:titleString];
    };
    
    [KEYWINDOW addSubview:self.identityPopView];
    [KEYWINDOW bringSubviewToFront:self.identityPopView];
    
    [KEYWINDOW addSubview:self.switchView];
    [KEYWINDOW bringSubviewToFront:self.switchView];
}

- (void)didSelectRowBlock:(PHAppraiserType)type title:(NSString *)titleString{
    _type = type;
    _titleView.titleString = titleString;
    [self getPicIdentifyList];
}

- (PHFreeIdentifyView *)popView{
    if (_popView == nil) {
        _popView = [[PHFreeIdentifyView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        [_popView popHiden];
    }
    return _popView;
}


/**
 开关 - 图片鉴定 - 实物鉴定
 */
- (PHIdentityBtnView *)switchView{
    if (_switchView == nil) {
        WS(ws);
        _switchView = [[PHIdentityBtnView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-SWITCH_HEIGHT)*0.5, HIDE_TAB_BAR_HEIGHT-mas_height(65), SWITCH_HEIGHT, SWITCH_HEIGHT)];
        _switchView.showStatusBlock = ^(BOOL status) {
            ws.identityPopView.hidden = status;
        };
    }
    return _switchView;
}

- (PHIdentityPopView *)identityPopView{
    if (_identityPopView == nil) {
        WS(ws);
        _identityPopView = [[PHIdentityPopView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _identityPopView.hideBlock = ^(NSInteger tag){
            [ws didSelectItemAtIndex:tag];
        };
    }
    return _identityPopView;
}

- (void)didSelectItemAtIndex:(NSInteger)tag{
    [_switchView hide];
    if (tag == 10)
    {
        WS(ws);
        PHFreeIdentiftyPicVC *picVC = [PHFreeIdentiftyPicVC new];
        picVC.updateIdentifyBlock = ^{
            [ws getPicIdentifyList];
        };
        picVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:picVC animated:YES];
    }
    else
    {
        PHFreeIdentiftyRealVC *realVC = [PHFreeIdentiftyRealVC new];
        realVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:realVC animated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (@available(iOS 11.0, *))
    {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    else
    {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    if (_productCount != 0)
        [_switchView show];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_switchView hide];
    _isOpenSwitch = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
