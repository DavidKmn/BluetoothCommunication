//
//  ViewController.swift
//  BluCom2
//
//  Created by David on 14/11/2017.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit

class StartController: UIViewController {
    
    lazy var becomePeripheralButton: UIButton = {
        let but = UIButton(type: .system)
        but.setTitle("Become Peripheral", for: .normal)
        but.backgroundColor = Constants.Color.lightSystem
        but.setTitleColor(.black, for: .normal)
        but.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        but.layer.masksToBounds = true
        but.layer.cornerRadius = 50
        but.titleLabel?.numberOfLines = 0
        but.titleLabel?.textAlignment = .center
        but.addTarget(self, action: #selector(handleBecomePeripheralTap), for: .touchUpInside)
        but.layer.borderWidth = 1
        but.translatesAutoresizingMaskIntoConstraints = false
        return but
    }()
    
    lazy var becomeCentralButton: UIButton = {
        let but = UIButton(type: .system)
        but.setTitle("Become Central", for: .normal)
        but.backgroundColor = Constants.Color.lightSystem
        but.setTitleColor(.black, for: .normal)
        but.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        but.layer.masksToBounds = true
        but.layer.cornerRadius = 50
        but.titleLabel?.numberOfLines = 0
        but.titleLabel?.textAlignment = .center
        but.addTarget(self, action: #selector(handleBecomeCentralTap), for: .touchUpInside)
        but.layer.borderWidth = 1
        but.translatesAutoresizingMaskIntoConstraints = false
        return but
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "Choose your role"

        view.backgroundColor = .white
        
        setupUI()
        
    }
    
    private func setupUI() {
        
        let buttonContainerView = UIView()

        view.addSubview(buttonContainerView)
        
        buttonContainerView.anchor(top: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor, topPadding: 0, leadingPadding: 0, bottomPadding: 0, trailingPadding: 0, width: 0, height: 300)
        buttonContainerView.anchorCenterYToSuperview()
        
        buttonContainerView.addSubview(becomePeripheralButton)
        
        becomePeripheralButton.anchor(top: buttonContainerView.topAnchor, leading: buttonContainerView.leadingAnchor, bottom: nil, trailing: buttonContainerView.trailingAnchor, topPadding: 0, leadingPadding: 0, bottomPadding: 0, trailingPadding: 0, width: 0, height: 100)
        
        buttonContainerView.addSubview(becomeCentralButton)
        
        becomeCentralButton.anchor(top: nil, leading: buttonContainerView.leadingAnchor, bottom: buttonContainerView.bottomAnchor, trailing: buttonContainerView.trailingAnchor, topPadding: 0, leadingPadding: 0, bottomPadding: 0, trailingPadding: 0, width: 0, height: 100)
        
    }
    
    @objc private func handleBecomePeripheralTap() {
        let peripheralManagerController = PeripheralManagerController()
        navigationController?.pushViewController(peripheralManagerController, animated: true)
    }
    
    @objc private func handleBecomeCentralTap() {
        let centralManagerController = CentralManagerController()
        navigationController?.pushViewController(centralManagerController, animated: true)
    }
}

