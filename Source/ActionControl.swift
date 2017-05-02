//
//  ActionControl.swift
//  ActionControl
//
//  Created by devedbox on 2017/4/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

public final class ActionControl: UIControl {
    /// Attached view to show action control rightly.
    public weak var view: UIView?
    /// Content view.
    public var contentView: UIView { return _contentView }
    fileprivate lazy var _contentView: UIView = { () -> UIView in
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    /// Placeholder view.
    fileprivate lazy var _placeholder: UIImageView = { () -> UIImageView in
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    /// Keywindow of the application.
    fileprivate let keyWindow = UIApplication.shared.keyWindow
    /// Showing direction.
    fileprivate var _direction: Direction = .default
    /// Is animating of the content view.
    fileprivate var _animatingHiding: Bool = false
    /// Content inset. Insets of the action control shows on key window. Default will be (20, 20, 20, 20).
    public var contentInset: UIEdgeInsets = UIEdgeInsetsMake(20, 20, 20, 20)
    
    public init(view: UIView) {
        super.init(frame: CGRect.zero)
        
        self.view = view
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - Types.

extension ActionControl {
    public enum Direction: Int {
        case `default`
        case top
        case left
        case bottom
        case right
        
        fileprivate static func proposed(of inside: CGRect, in rect: CGRect) -> Direction {
            return .bottom
        }
    }
    
    private enum Animation: Int {
        case fade
    }
}

// MARK: - Overrides.

extension ActionControl {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        guard isFirstResponder else { return view }
        if !_contentView.frame.contains(point), !_placeholder.frame.contains(point) {
            resignFirstResponder()
        }
        return view
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard self.canBecomeFirstResponder else { return }
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        _showShadow(_direction)
    }
}

// MARK: - Responder.

extension ActionControl {
    /// Returns a Boolean value indicating whether this object can become the first responder.
    /// This method returns false by default. Subclasses must override this method and return true to be able to become first responder.
    /// Do not call this method on a view that is not currently in the active view hierarchy. The result is undefined.
    /// - Returns: true if the receiver can become the first responder or false if it cannot.
    public override var canBecomeFirstResponder: Bool { return view == nil||keyWindow == nil||view?.window == nil||view?.superview == nil ? false : true }
    /// Asks UIKit to make this object the first responder in its window.
    /// Call this method when you want to the current object to be the first responder. Calling this method is not a guarantee that the object will become the first responder. UIKit asks the current first responder to resign as first responder, which it might not. If it does, UIKit calls this object's canBecomeFirstResponder method, which returns false by default. If this object succeeds in becoming the first responder, subsequent events targeting the first responder are delivered to this object first and UIKit attempts to display the object's input view, if any.
    /// Never call this method on a view that is not part of an active view hierarchy. You can determine whether the view is onscreen, by checking its window property. If that property contains a valid window, it is part of an active view hierarchy. If that property is nil, the view is not part of a valid view hierarchy.
    /// You can override this method in your custom responders to update your object's state or perform some action such as highlighting the selection. If you override this method, you must call super at some point in your implementation.
    /// - Returns: true if this object is now the first-responder or false if it is not.
    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        guard let keyWindow = self.keyWindow else { return super.becomeFirstResponder() }
        guard let view = self.view else { return super.becomeFirstResponder() }
        
        // Add to key window.
        keyWindow.addSubview(self)
        self.addSubview(_contentView)
        
        keyWindow.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[self]|", metrics: nil, views: ["self": self]))
        keyWindow.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[self]|", metrics: nil, views: ["self": self]))
        
        // Add contraints.
        
        let attachedRect = keyWindow.convert(view.frame, from: view.superview!)
        // Add placeholder to self.
        _setupPlaceholderView(attachedRect)
        let visibleRect = keyWindow.bounds.insetBy(contentInset)
        
        let direction = Direction.proposed(of: attachedRect, in: visibleRect)
        
        switch direction {
        case .top:
            let width = NSLayoutConstraint(item: _contentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: attachedRect.width)
            let height = NSLayoutConstraint(item: _contentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: attachedRect.origin.y-visibleRect.origin.y)
            _contentView.addConstraints([width, height])
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[_contentView][_placeholder]", metrics: nil, views: ["_contentView": _contentView, "_placeholder": _placeholder]))
            addConstraint(NSLayoutConstraint(item: _placeholder, attribute: .left, relatedBy: .equal, toItem: _contentView, attribute: .left, multiplier: 1.0, constant: 0.0))
        case .left:
            let width = NSLayoutConstraint(item: _contentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: attachedRect.width)
            let height = NSLayoutConstraint(item: _contentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: visibleRect.height-attachedRect.origin.y)
            _contentView.addConstraints([width, height])
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[_contentView][_placeholder]", metrics: nil, views: ["_contentView": _contentView, "_placeholder": _placeholder]))
            addConstraint(NSLayoutConstraint(item: _placeholder, attribute: .top, relatedBy: .equal, toItem: _contentView, attribute: .top, multiplier: 1.0, constant: 0.0))
        case .bottom:
            let width = NSLayoutConstraint(item: _contentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: attachedRect.width)
            let height = NSLayoutConstraint(item: _contentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: visibleRect.maxY-attachedRect.origin.y)
            _contentView.addConstraints([width, height])
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[_placeholder][_contentView]", metrics: nil, views: ["_contentView": _contentView, "_placeholder": _placeholder]))
            addConstraint(NSLayoutConstraint(item: _placeholder, attribute: .left, relatedBy: .equal, toItem: _contentView, attribute: .left, multiplier: 1.0, constant: 0.0))
        case .right:
            let width = NSLayoutConstraint(item: _contentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: attachedRect.width)
            let height = NSLayoutConstraint(item: _contentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: visibleRect.height-attachedRect.origin.y)
            _contentView.addConstraints([width, height])
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[_placeholder][_contentView]", metrics: nil, views: ["_contentView": _contentView, "_placeholder": _placeholder]))
            addConstraint(NSLayoutConstraint(item: _placeholder, attribute: .top, relatedBy: .equal, toItem: _contentView, attribute: .top, multiplier: 1.0, constant: 0.0))
        default:
            return false
        }
        
        _direction = direction
        setNeedsLayout()
        layoutIfNeeded()
        setNeedsDisplay()
        
        _show(animated: true)
        
        return super.becomeFirstResponder()
    }
    /// Returns a Boolean value indicating whether the receiver is willing to relinquish first-responder status.
    /// This method returns true by default. You can override this method in your custom responders and return a different value if needed. For example, a text field containing invalid content might want to return false to ensure that the user corrects that content first.
    /// - Returns: true if the receiver can resign first-responder status, false otherwise.
    public override var canResignFirstResponder: Bool { return self.isFirstResponder }
    /// Notifies this object that it has been asked to relinquish its status as first responder in its window.
    /// The default implementation returns true, resigning first responder status. You can override this method in your custom responders to update your object's state or perform other actions, such as removing the highlight from a selection. You can also return false, refusing to relinquish first responder status. If you override this method, you must call super (the superclass implementation) at some point in your code.
    @discardableResult
    public override func resignFirstResponder() -> Bool {
        guard isFirstResponder else { return false }
        
        _hide(true)
        
        return super.resignFirstResponder()
    }
    /// Returns a Boolean value indicating whether this object is the first responder.
    /// UIKit dispatches some types of events, such as motion events, to the first responder initially.
    /// - Returns: true if the receiver is the first responder or false if it is not.
    // public override var isFirstResponder: Bool { return super.isFirstResponder && !_animatingHiding}
}

extension ActionControl {
    fileprivate func _setupPlaceholderView(_ rect: CGRect) -> Swift.Void {
        self.addSubview(_placeholder)
        
        _placeholder.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[_placeholder(width)]", metrics: ["width": rect.width], views: ["_placeholder": _placeholder]))
        _placeholder.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[_placeholder(height)]", metrics: ["height": rect.height], views: ["_placeholder": _placeholder]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(left)-[_placeholder]", metrics: ["left": rect.origin.x], views: ["_placeholder": _placeholder]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[_placeholder]", metrics: ["top": rect.origin.y], views: ["_placeholder": _placeholder]))
    }
    
    fileprivate func _showShadow(_ direction: Direction) -> Swift.Void {
        _contentView.layer.shadowOpacity = 0.2
        _contentView.layer.shadowRadius = 5
        _contentView.layer.shadowOffset = .zero
        
        switch direction {
        case .top:
            let path = UIBezierPath()
            let frame = _contentView.bounds
            path.move(to: frame.leftTop)
            path.addLine(to: frame.rightTop)
            path.addLine(to: frame.rightBottom)
            path.addLine(to: frame.inside(offset: .zero))
            path.addLine(to: frame.leftBottom)
            path.addLine(to: frame.leftTop)
            path.close()
            _contentView.layer.shadowPath = path.cgPath
        case .left:
            _contentView.layer.shadowPath = UIBezierPath(roundedRect: _contentView.bounds, cornerRadius: 0.0).cgPath
        case .bottom:
            let path = UIBezierPath()
            let frame = _contentView.bounds
            path.move(to: frame.leftTop)
            path.addLine(to: frame.inside(offset: .zero))
            path.addLine(to: frame.rightTop)
            path.addLine(to: frame.rightBottom)
            path.addLine(to: frame.leftBottom)
            path.addLine(to: frame.leftTop)
            path.close()
            _contentView.layer.shadowPath = path.cgPath
        case .right:
            _contentView.layer.shadowPath = UIBezierPath(roundedRect: _contentView.bounds, cornerRadius: 0.0).cgPath
        default: _contentView.layer.shadowPath = nil
        }
    }
    
    fileprivate func _show(animated: Bool) -> Swift.Void {
        /*
        let constraints = _contentView.constraints.filter { $0.firstAttribute == .height }
        guard let constraint = constraints.first else { return }
        
        let height = constraint.constant
        constraint.constant = 0.0
        
        setNeedsLayout()
        layoutIfNeeded()
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.9, options: UIViewAnimationOptions(rawValue: 7), animations: { [unowned self] in
            constraint.constant = height
            
            self.setNeedsDisplay()
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }, completion: nil)
         */
        _contentView.alpha = 0.0
        
        UIView.animate(withDuration: 0.35, animations: { [unowned self] in
            self.contentView.alpha = 1.0
        }, completion: nil)
    }
    
    fileprivate func _hide(_ animated: Bool) -> Swift.Void {
        _animatingHiding = true
        UIView.animate(withDuration: 0.25, animations: { [unowned self] in
            self.contentView.alpha = 0.0
        }) { [unowned self] finished in
            guard finished else { return }
            
            self._animatingHiding = false
            self.removeFromSuperview()
            self.contentView.alpha = 1.0
        }
    }
}

extension CGRect {
    /// Returns a rectangle that is smaller or larger than the source rectangle, with the same center point.
    /// The rectangle is standardized and then the inset parameters are applied. If the resulting rectangle would have a negative height or width, a null rectangle is returned.
    /// - Parameters:
    ///   - insets: The values to use for adjusting the source rectangle. To create an inset rectangle, specify a positive value. To create a larger, encompassing rectangle, specify a negative value.
    /// - Returns:
    /// A rectangle. The origin value is offset in the x-axis by the distance specified by the `inset.left` and in the y-axis by the distance specified by the `inset.top`, and its size adjusted by (insets.left+inset.right, insets.top+insets.bottom), relative to the source rectangle. If insets is positive values, then the rectangle’s size is decreased. If insets is negative values, the rectangle’s size is increased.
    public func insetBy(_ insets: UIEdgeInsets) -> CGRect {
        return CGRect(x: origin.x + insets.left, y: origin.y + insets.top, width: width - (insets.left+insets.right), height: height - (insets.top+insets.bottom))
    }
    /// Get the center point of the rectangle.
    public var center: CGPoint { return CGPoint(x: midX, y: midY) }
    /// Get the left-top point of the rectangle.
    public var leftTop: CGPoint { return origin }
    /// Get the right-top point of the rectangle.
    public var rightTop: CGPoint { return CGPoint(x: maxX, y: origin.y) }
    /// Get the left-bottom point of the rectangle.
    public var leftBottom: CGPoint { return CGPoint(x: origin.x, y: maxY) }
    /// Get the right-bottom point of the rectangle.
    public var rightBottom: CGPoint { return CGPoint(x: maxX, y: maxY) }
    /// Returns a point inside the rectangle by offset the `offset` values to the center of the rectangle.
    /// - Parameters:
    ///   - offset: Offset of the center point.
    public func inside(offset: CGPoint) -> CGPoint { return CGPoint(x: max(minX, min(center.x+offset.x, maxX)), y: max(minY, min(center.y+offset.y, maxY))) }
}
