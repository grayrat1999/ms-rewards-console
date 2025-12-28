package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"sync"
	"time"
)

// ---------- 数据结构 ----------

type Task struct {
	Number int `json:"number"`
	// 任务名称
	Name string `json:"name"`
	// 任务时间, 格式: yyyyMMdd
	Time string `json:"time"`
	// 任务进度
	Progress int `json:"progress"`
	// 任务目标
	Target int `json:"target"`
	// 1 完成, 0 未完成
	Done int `json:"done"`
}
type MetaData struct {
	// 最大执行次数
	MaxExecCount int `json:"max_exec_count"`
	// 最大暂停时间, 单位: s
	MaxPauseTime int `json:"max_pause_time"`
}

var (
	meta = MetaData{
		MaxExecCount: 30,
		MaxPauseTime: 60,
	}
	// 使用 map 保存任务，key格式: name + "_" + time
	taskMap = make(map[string]Task)
	// 互斥锁
	mu sync.RWMutex
	// 日期格式变量
	dateLayout = "20060102"
)

// ---------- 工具函数 ----------

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}

// ---------- 最大执行次数接口 ----------

func mateHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		mu.RLock()
		defer mu.RUnlock()
		writeJSON(w, meta)
	case http.MethodPost:
		var req MetaData
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "invalid json", http.StatusBadRequest)
			return
		}
		mu.Lock()
		if req.MaxExecCount != 0 {
			meta.MaxExecCount = req.MaxExecCount
		}
		mu.Unlock()
		writeJSON(w, meta)
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

// ---------- 任务接口 ----------

func taskHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodPost:
		saveOrUpdateTask(w, r)
	case http.MethodGet:
		queryTasks(w, r)
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

// ---------- 保存或更新任务并清理 30 天前记录 ----------
func saveOrUpdateTask(w http.ResponseWriter, r *http.Request) {
	var task Task
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}

	_, err := time.Parse(dateLayout, task.Time)
	if err != nil {
		http.Error(w, "invalid task time format, expect yyyyMMdd", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	// 清理 30 天前的记录
	cutoff := time.Now().AddDate(0, 0, -30)
	for key, t := range taskMap {
		tTime, err := time.Parse(dateLayout, t.Time)
		if err != nil {
			continue
		}
		if tTime.Before(cutoff) {
			delete(taskMap, key)
		}
	}

	// 唯一键 = name + "_" + time
	key := task.Name + "_" + task.Time
	if task.Progress >= task.Target {
		task.Done = 1
	} else {
		task.Done = 0
	}
	taskMap[key] = task // 不存在则插入，存在则覆盖（更新）

	writeJSON(w, map[string]string{"message": "success"})
}

// ---------- 查询任务 ----------
func queryTasks(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	timeStr := r.URL.Query().Get("time")
	done := r.URL.Query().Get("done")

	mu.RLock()
	defer mu.RUnlock()

	result := make([]Task, 0)
	for _, t := range taskMap {
		if name != "" && t.Name != name {
			continue
		}
		if timeStr != "" && t.Time != timeStr {
			continue
		}
		if done != "" {
			if done == "1" && t.Done != 1 {
				continue
			}
			if done == "0" && t.Done != 0 {
				continue
			}
		}
		result = append(result, t)
	}

	// 按时间降序，再按进度升序排序
	sort.Slice(result, func(i, j int) bool {
		timeI, errI := time.Parse(dateLayout, result[i].Time)
		timeJ, errJ := time.Parse(dateLayout, result[j].Time)
		if errI != nil || errJ != nil {
			// 时间解析失败时按进度升序
			return result[i].Progress < result[j].Progress
		}

		if !timeI.Equal(timeJ) {
			return timeI.After(timeJ) // 时间降序
		}
		return result[i].Progress < result[j].Progress // 进度升序
	})

	writeJSON(w, result)
}

// ---------- 根路径返回 index.html ----------
func indexHandler(w http.ResponseWriter, r *http.Request) {
	ex, _ := os.Executable()
	dir := filepath.Dir(ex)
	http.ServeFile(w, r, filepath.Join(dir, "index.html"))
}

// ---------- main ----------
func main() {
	http.HandleFunc("/", indexHandler)
	http.HandleFunc("/meta", mateHandler)
	http.HandleFunc("/tasks", taskHandler)

	log.Println("Server started at :3000")
	log.Fatal(http.ListenAndServe(":3000", nil))
}
