import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Check if user is logged in
        if AuthService.shared.isUserLoggedIn {
            setupMainInterface()
        } else {
            presentLoginScreen()
        }
        
        window?.makeKeyAndVisible()
    }
    
    private func setupMainInterface() {
        let tabBarController = UITabBarController()
        
        // Home Tab
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        
        // Files Tab
        let filesVC = FileBrowserViewController()
        let filesNav = UINavigationController(rootViewController: filesVC)
        filesNav.tabBarItem = UITabBarItem(title: "Files", image: UIImage(systemName: "folder"), tag: 1)
        
        // Camera Tab
        let cameraVC = CameraViewController()
        let cameraNav = UINavigationController(rootViewController: cameraVC)
        cameraNav.tabBarItem = UITabBarItem(title: "Camera", image: UIImage(systemName: "camera"), tag: 2)
        
        // Settings Tab
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 3)
        
        tabBarController.viewControllers = [homeNav, filesNav, cameraNav, settingsNav]
        tabBarController.selectedIndex = 0
        
        window?.rootViewController = tabBarController
    }
    
    private func presentLoginScreen() {
        let loginVC = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginVC)
        window?.rootViewController = navigationController
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Save changes in the application's managed object context when the scene transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
