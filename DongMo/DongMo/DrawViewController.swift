//
//  DrawViewController.swift
//  DongMo
//
//  Created by kimdonghyun on 2019/11/01.
//  Copyright © 2019 kimdonghyun. All rights reserved.
//

import UIKit
import PencilKit

class DrawViewController: UIViewController {
    
    let canvasView = PKCanvasView(frame: .zero)
    
    @IBOutlet weak var navigationBar: UINavigationBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func setNavigationBar() {
        if let navItem = navigationBar.topItem{
            let saveItem = UIBarButtonItem(title: "저장", style: .done, target: self, action: #selector(saveImage))
            
            let clearItem = UIBarButtonItem(title: "지움", style: .plain, target: self, action: #selector(clear))
            
            let toggleItem = UIBarButtonItem(title: "숨김", style: .plain, target: self, action: #selector(togglePicker))

            navItem.rightBarButtonItems?.append(clearItem)
            navItem.rightBarButtonItems?.append(toggleItem)
            navItem.rightBarButtonItems?.append(saveItem)
        }
        
    }

    @objc func saveImage() {
        let image = canvasView.drawing.image(from: canvasView.drawing.bounds, scale: 1.0)
        
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
    }
    
    @objc func clear() {
        canvasView.drawing = PKDrawing()
    }
    
    @objc func togglePicker() {
        if canvasView.isFirstResponder{
            canvasView.resignFirstResponder()
        }else{
            canvasView.becomeFirstResponder()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard
            let window = view.window,
            let toolPicker = PKToolPicker.shared(for: window) else { return }

        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }


}

