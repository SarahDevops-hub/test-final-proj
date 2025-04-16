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
        stage('Fix Permissions') {
            steps {
                echo "🔧 Fixing file permissions..."
                sh '''
                docker-compose exec -T wp-cli bash -c '
                chown -R www-data:www-data /var/www/html/wp-content
                chmod -R 775 /var/www/html/wp-content
                '
                '''
            }
        }

        stage('Install and Activate Theme') {
            steps {
                sh '''
                whoami
                docker-compose exec -T --user=www-data wp-cli bash -c '
                cd /var/www/html

                THEME_NAME="astra"

                if ! wp theme is-installed $THEME_NAME --allow-root; then
                    echo "📦 Installing theme: $THEME_NAME"
                    wp theme install $THEME_NAME --activate --allow-root
                else
                    echo "🎨 Theme $THEME_NAME is already installed. Activating..."
                    wp theme activate $THEME_NAME --allow-root
                fi

                echo "✅ Theme $THEME_NAME is now active."
                '
                '''
            }
        }
        stage('Verify Theme') {
            steps {
                sh '''
                docker-compose exec -T wp-cli wp theme list --status=active
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