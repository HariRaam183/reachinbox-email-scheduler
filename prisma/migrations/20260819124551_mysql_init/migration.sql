-- CreateTable
CREATE TABLE `User` (
    `id` VARCHAR(191) NOT NULL,
    `googleId` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `avatarUrl` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `User_googleId_key`(`googleId`),
    UNIQUE INDEX `User_email_key`(`email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Sender` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `displayName` VARCHAR(191) NOT NULL,
    `etherealUsername` VARCHAR(191) NOT NULL,
    `etherealPassword` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `Sender_userId_idx`(`userId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `EmailJob` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `senderId` VARCHAR(191) NOT NULL,
    `recipient` VARCHAR(191) NOT NULL,
    `subject` VARCHAR(191) NOT NULL,
    `body` VARCHAR(191) NOT NULL,
    `scheduledAt` DATETIME(3) NOT NULL,
    `sentAt` DATETIME(3) NULL,
    `status` ENUM('scheduled', 'processing', 'sent', 'failed') NOT NULL DEFAULT 'scheduled',
    `attempts` INTEGER NOT NULL DEFAULT 0,
    `lastError` VARCHAR(191) NULL,
    `bullmqJobId` VARCHAR(191) NULL,
    `idempotencyKey` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `EmailJob_idempotencyKey_key`(`idempotencyKey`),
    INDEX `EmailJob_userId_status_idx`(`userId`, `status`),
    INDEX `EmailJob_senderId_scheduledAt_idx`(`senderId`, `scheduledAt`),
    INDEX `EmailJob_status_scheduledAt_idx`(`status`, `scheduledAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `Sender` ADD CONSTRAINT `Sender_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmailJob` ADD CONSTRAINT `EmailJob_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmailJob` ADD CONSTRAINT `EmailJob_senderId_fkey` FOREIGN KEY (`senderId`) REFERENCES `Sender`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
