//
//  NTextView.m
//  Pods
//
//  Created by Naithar on 23.04.15.
//
//

#import "NHTextView.h"

@interface NHTextView ()

@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) id textChangeObserver;

@end

@implementation NHTextView

- (instancetype)init {
    self = [super init];

    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame
                  textContainer:textContainer];

    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.layoutManager.allowsNonContiguousLayout = NO;

    //create label
    //UIColor(red: 0, green: 0, blue: 0.098, alpha: 0.22)
    //textChangeObserver = UITextViewTextDidChangeNotification
}


- (void)setText:(NSString *)text {
    [super setText:text];
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.textChangeObserver];
}

@end


//public class PlaceholderTextView: UITextView {
//
//    override public var font: UIFont! {
//        didSet {
//            self.placeholderLabel?.font = self.font
//        }
//    }
//
//    override public dynamic var text: String! {
//        didSet {
//            self.textChanged(nil)
//            //            NSNotificationCenter.defaultCenter().postNotificationName(UITextViewTextDidChangeNotification, object: nil);
//        }
//    }
//    //    override public var textColor: UIColor! {
//    //        didSet {
//    //            self.placeholderLabel?.textColor = self.textColor != nil ? self.textColor.colorWithAlphaComponent(0.35)
//    //                : UIColor(white: 0.85, alpha: 1)
//    //        }
//    //    }
//    var placeholderLabel : UILabel!
//
//    required public init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//
//        self.createLabel()
//    }
//
//    override init(frame: CGRect, textContainer: NSTextContainer?) {
//        super.init(frame: frame, textContainer: textContainer)
//
//        self.createLabel()
//    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.createLabel()
//    }
//
//    func createLabel() {
//        if self.placeholderLabel != nil {
//            return
//        }
//
//        self.placeholderLabel = UILabel(frame: CGRectZero)
//        //R:0 G:0 B:0.098 A:0.22
//        self.placeholderLabel.textColor = UIColor(red: 0, green: 0, blue: 0.098, alpha: 0.22)
//        self.placeholderLabel.numberOfLines = 1
//        self.placeholderLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail
//        self.placeholderLabel.backgroundColor = UIColor.clearColor()
//        if self.font != nil {
//            self.placeholderLabel.font = self.font
//        }
//        self.addSubview(self.placeholderLabel)
//
//        layout(self.placeholderLabel) { view in
//            view.left == view.superview!.left + 5
//            view.right == view.superview!.right - 5
//            view.top == view.superview!.top + 7.5
//        }
//
//        self.placeholderLabel.textAlignment = NSTextAlignment.Left
//        self.placeholderLabel.hidden = self.text != nil && self.text.utf16Count > 0
//
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textChanged:", name: UITextViewTextDidChangeNotification, object: self)
//    }
//
//    func textChanged(notification: NSNotification!) {
//        if self.text != nil && self.text.utf16Count > 0 {
//            self.placeholderLabel?.hidden = true
//        }
//        else {
//            self.placeholderLabel?.hidden = false
//        }
//    }
//    deinit {
//        NSNotificationCenter.defaultCenter().removeObserver(self)
//    }
//    
//}