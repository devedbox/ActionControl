//
//  ViewController.swift
//  ActionControl
//
//  Created by devedbox on 2017/4/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        label.layer.borderWidth = 0.5
        label.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func show(_ sender: UITapGestureRecognizer) {
        let actionControl = ActionControl(view: label)
        actionControl.becomeFirstResponder()
    }
}

