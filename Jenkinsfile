pipeline {
    agent any

    environment {
        SONAR_PROJECT_KEY = 'devopsprojectteam_computer-stopre'
        SONAR_ORG = 'devopsprojectteam'
        SONAR_HOST = 'https://sonarcloud.io'
        SONAR_TOKEN = credentials('SONAR_TOKEN')
    }


    stages {

        stage('Setup test environment') {
            steps {
                echo "📦 Bringing up the test environment..."
                sh '''
                # 1. Force remove specific containers if they exist
                docker rm -f mysql_db wordpress_app wp_cli 2>/dev/null || true
                
                docker-compose down --volumes --remove-orphans --timeout 1 2>/dev/null || true                

                docker-compose up -d
                '''
            }
        }
        stage('Wait for WordPress') {
            steps {
                script {
                    def maxAttempts = 20
                    def attempt = 1
                    while (attempt <= maxAttempts) {
                        try {
                            sh 'docker exec wordpress_app curl -s localhost'
                            echo "✅ WordPress is ready!"
                            break
                        } catch (Exception e) {
                            echo "Attempt ${attempt}: WordPress not ready yet, waiting..."
                            sleep time: 10, unit: 'SECONDS'
                            attempt++
                        }
                    }
                    if (attempt > maxAttempts) {
                        error "WordPress did not become ready after ${maxAttempts} attempts."
                    }
                }
            }
        }
        stage('Install WordPress if not installed') {
            steps {
                script {
                    def publicIP = sh(
                        script: '''
                            TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \\
                                -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
                            curl -sH "X-aws-ec2-metadata-token: $TOKEN" \\
                                http://169.254.169.254/latest/meta-data/public-ipv4
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "📡 Retrieved Public IP: [${publicIP}]"



                    def wpUrl = "http://${publicIP}:3000"
                    sleep time: 10, unit: 'SECONDS'

                    sh """
                    docker compose exec -T wp-cli bash -c '
                    cd /var/www/html

                    if ! wp core is-installed; then
                        wp core install \\
                            --url="${wpUrl}" \\
                            --title="Test Site" \\
                            --admin_user="devops" \\
                            --admin_password="team" \\
                            --admin_email="admin@example.com"
                    else
                        echo "WordPress is already installed."
                        wp option update home "${wpUrl}"
                        wp option update siteurl "${wpUrl}"
                    fi
                    '
                    """
                }
            }
        }


        stage('Run WP-CLI Tests') {
            steps {
                echo "🧪 Running WP-CLI custom tests..."
                sh '''
                docker-compose exec -T wp-cli bash -c '
                wp --require=/var/www/html/wp-cli-test-command.php test
                '
                '''
            }
        }
        stage('Install and Activate Theme') {
            steps {
                sh '''
                    # Install unzip in WordPress container
                    docker-compose exec -T wordpress apt-get update
                    docker-compose exec -T wordpress apt-get install -y unzip
                    
                    # Download and install theme
                    docker-compose exec -T wordpress bash -c '
                        cd /var/www/html/wp-content/themes
                        curl -O https://downloads.wordpress.org/theme/astra.4.10.0.zip
                        unzip -o astra.4.10.0.zip
                        rm astra.4.10.0.zip
                        chown -R www-data:www-data astra
                        chmod -R 755 astra
                    '
                    
                    # Verify theme installation
                    docker-compose exec -T wordpress ls -la /var/www/html/wp-content/themes/astra
                    
                    # Now activate the theme using wp-cli
                    docker-compose exec -T wp-cli wp theme activate astra
                '''
            }
        }
        stage('Install and Setup Dummy Data') {
            steps {
                sh '''
                    # Download and install importer plugin directly using WordPress container
                    docker-compose exec -T wordpress bash -c '
                        cd /var/www/html/wp-content/plugins
                        curl -O https://downloads.wordpress.org/plugin/wordpress-importer.0.8.4.zip
                        unzip -o wordpress-importer.0.8.4.zip
                        rm wordpress-importer.0.8.4.zip
                        chown -R www-data:www-data wordpress-importer
                        chmod -R 755 wordpress-importer
                    '
                    
                    # Download sample data using WordPress container
                    docker-compose exec -T wordpress bash -c '
                        cd /var/www/html
                        curl -O https://raw.githubusercontent.com/WPTRT/theme-unit-test/master/themeunittestdata.wordpress.xml
                        chown www-data:www-data themeunittestdata.wordpress.xml
                        chmod 644 themeunittestdata.wordpress.xml
                    '
                    
                    # Now use wp-cli for WordPress operations
                    docker-compose exec -T wp-cli bash -c '
                        cd /var/www/html
                        
                        # Activate the importer plugin
                        wp plugin activate wordpress-importer
                        
                        # Import the data
                        wp import themeunittestdata.wordpress.xml --authors=create
                        
                        # Create menus
                        wp menu create "Primary Menu"
                        wp menu create "Footer Menu"
                        
                        # Add menu items
                        wp menu item add-post primary-menu 2
                        wp menu item add-custom primary-menu "Home" --url="/"
                        wp menu item add-custom primary-menu "About" --url="/about"
                        wp menu item add-custom primary-menu "Contact" --url="/contact"
                        
                        # Assign menu location
                        wp menu location assign primary-menu primary
                        
                        # Update settings
                        wp option update posts_per_page 10
                        wp option update permalink_structure "/%postname%/"
                    '
                    
                    # Clean up using WordPress container
                    docker-compose exec -T wordpress bash -c '
                        cd /var/www/html
                        rm -f themeunittestdata.wordpress.xml
                        rm -rf wp-content/plugins/wordpress-importer
                    '
                    
                    echo "✅ Dummy data installation completed!"
                '''
            }
        }

        stage('Tear Down Test Environment') {
            steps {
                echo "🧹 Tearing down test environment..."
                sh 'docker compose down'
            }
        }
        stage('Deploy to Production') {
            steps {
                script {
                    def publicIP = sh(
                        script: '''
                            TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \\
                                -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
                            curl -sH "X-aws-ec2-metadata-token: $TOKEN" \\
                                http://169.254.169.254/latest/meta-data/public-ipv4
                        ''',
                        returnStdout: true
                    ).trim()

                    sh 'docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d'

                    echo "✅ Deployment to production completed."
                    echo "🌐 Production Site URL: http://${publicIP}:3000"
                }
            }
        }
    }
    post {
        success {
            echo "Cleaning up workspace and Docker images..."
            sh "docker system prune -f"
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "🚨 Pipeline failed. Check logs for more info."
        }
        always {
            cleanWs()
        }
    }
}